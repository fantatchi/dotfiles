#!/usr/bin/env python3
"""Send Obsidian daily/weekly summary by Gmail SMTP.

Usage:
    python3 send-summary.py daily YYYY-MM-DD
    python3 send-summary.py weekly YYYY-MM-DD

Required credentials (resolved by keyring service "obsidian-mail"):
    OBSIDIAN_SUMMARY_SMTP_USER  Gmail address used for SMTP login
    OBSIDIAN_SUMMARY_SMTP_PASS  Google App Password (16 chars, no spaces)

Optional:
    OBSIDIAN_SUMMARY_MAIL_TO    Recipient address (default: SMTP_USER)
    OBSIDIAN_SUMMARY_MAIL_FROM  From address (default: SMTP_USER)

Setup (per machine, one-time):
    Windows (keyring -> Windows Credential Manager):
        python -m keyring set obsidian-mail OBSIDIAN_SUMMARY_SMTP_USER
        python -m keyring set obsidian-mail OBSIDIAN_SUMMARY_SMTP_PASS
    WSL/Linux (keyring backend unavailable by default):
        Pass values via environment variable at invocation time. See override below.

Override at runtime (テスト用; env が keyring より優先):
    OBSIDIAN_SUMMARY_SMTP_USER=... OBSIDIAN_SUMMARY_SMTP_PASS=... \\
        python3 send-summary.py ...

Behavior:
    - Calls extract-summary.py to obtain subject / body_markdown / body_html
    - If empty=true (target summary missing): does NOT send. Exits with status 0
      and a JSON `{"sent": false, "reason": "empty", ...}` on stdout
    - Otherwise sends a multipart/alternative message via smtp.gmail.com:465 (SSL)
    - On success, prints `{"sent": true, ...}` JSON

Exit codes:
    0  処理成功（empty スキップ含む）
    2  引数 / 環境変数エラー
    3  SMTP 送信エラー
"""
from __future__ import annotations

import json
import os
import smtplib
import ssl
import subprocess
import sys
from email.message import EmailMessage
from email.utils import formataddr, formatdate, make_msgid

import keyring
import keyring.errors

# Windows のデフォルト stdout/stderr エンコーディング (cp932 等) では
# 日本語や非 ASCII 記号を含む JSON 結果を書き出せず UnicodeEncodeError になるため UTF-8 に固定する。
# scheduled-task / claude.app routine 起動時に PYTHONIOENCODING が引き継がれないケースの保険。
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
EXTRACT_SCRIPT = os.path.join(SCRIPT_DIR, "extract-summary.py")

SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 465

KEYRING_SERVICE = "obsidian-mail"


def fail(msg: str, code: int = 2) -> None:
    print(msg, file=sys.stderr)
    sys.exit(code)


def get_secret(name: str, required: bool = True) -> str:
    """Resolve a secret in priority order:

    1. Environment variable (ad-hoc CLI override / testing)
    2. OS credential store via keyring
       (Windows: WinCred / DPAPI per-user; WSL/Linux: only when a usable
       backend is installed — default `fail.Keyring` returns None)

    Returns "" for missing optional keys (caller decides default).
    Fails with setup instructions if `required` and both sources empty.
    """
    val = os.environ.get(name, "").strip()
    if val:
        return val
    try:
        val = keyring.get_password(KEYRING_SERVICE, name)
    except keyring.errors.KeyringError as e:
        if required:
            fail(
                f"keyring backend エラー ({name}): {e}\n"
                f"Windows: python -m keyring set {KEYRING_SERVICE} {name}\n"
                f"WSL: 環境変数で渡すか keyrings.alt 等を導入"
            )
        return ""
    if val:
        return val.strip()
    if required:
        fail(
            f"secret {name!r} が未登録です。以下で登録してください:\n"
            f"  python3 -m keyring set {KEYRING_SERVICE} {name}\n"
            f"(対話プロンプトで値を入力、echo されません)\n"
            f"WSL で keyring backend が無い場合は環境変数経由で渡してください"
        )
    return ""


def run_extract(mode: str, date_str: str) -> dict:
    res = subprocess.run(
        [sys.executable, EXTRACT_SCRIPT, mode, date_str],
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if res.returncode != 0:
        fail(f"extract-summary.py 失敗 (exit={res.returncode}):\n{res.stderr}", 2)
    try:
        return json.loads(res.stdout)
    except json.JSONDecodeError as e:
        fail(f"extract-summary.py の JSON パース失敗: {e}\n{res.stdout[:500]}", 2)


def build_message(data: dict, mail_from: str, mail_to: str) -> EmailMessage:
    msg = EmailMessage()
    msg["Subject"] = data["subject"]
    msg["From"] = formataddr(("Obsidian Mail", mail_from))
    msg["To"] = mail_to
    msg["Date"] = formatdate(localtime=True)
    msg["Message-ID"] = make_msgid(domain="obsidian-mail.local")
    msg.set_content(data["body_markdown"])
    msg.add_alternative(data["body_html"], subtype="html")
    return msg


def send(msg: EmailMessage, smtp_user: str, smtp_pass: str) -> None:
    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context, timeout=30) as s:
        s.login(smtp_user, smtp_pass)
        s.send_message(msg)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        fail(__doc__ or "usage error")
    mode, date_str = argv[1], argv[2]
    if mode not in ("daily", "weekly"):
        fail(f"mode は daily / weekly のいずれか: {mode!r}")

    smtp_user = get_secret("OBSIDIAN_SUMMARY_SMTP_USER")
    smtp_pass = get_secret("OBSIDIAN_SUMMARY_SMTP_PASS")
    mail_to = (get_secret("OBSIDIAN_SUMMARY_MAIL_TO", required=False) or smtp_user).strip()
    mail_from = (get_secret("OBSIDIAN_SUMMARY_MAIL_FROM", required=False) or smtp_user).strip()

    data = run_extract(mode, date_str)

    if data.get("empty"):
        result = {
            "sent": False,
            "reason": "empty",
            "mode": data.get("mode"),
            "target_date": data.get("target_date"),
            "week_start": data.get("week_start"),
            "week_end": data.get("week_end"),
            "missing_dates": data.get("missing_dates", []),
        }
        json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return 0

    msg = build_message(data, mail_from, mail_to)
    try:
        send(msg, smtp_user, smtp_pass)
    except smtplib.SMTPAuthenticationError as e:
        fail(
            "SMTP 認証失敗 (アプリパスワード不正またはアカウント設定):\n"
            f"  code: {e.smtp_code}\n  msg: {e.smtp_error.decode('utf-8', 'replace')}",
            3,
        )
    except smtplib.SMTPException as e:
        fail(f"SMTP 送信エラー: {e}", 3)
    except OSError as e:
        fail(f"SMTP 接続エラー: {e}", 3)

    result = {
        "sent": True,
        "mode": data.get("mode"),
        "target_date": data.get("target_date"),
        "week_start": data.get("week_start"),
        "week_end": data.get("week_end"),
        "available_dates": data.get("available_dates", []),
        "missing_dates": data.get("missing_dates", []),
        "to": mail_to,
        "subject": data["subject"],
    }
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
