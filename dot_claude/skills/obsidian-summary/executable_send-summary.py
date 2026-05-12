#!/usr/bin/env python3
"""Send Obsidian daily/weekly summary by Gmail SMTP.

Usage:
    python3 send-summary.py daily YYYY-MM-DD
    python3 send-summary.py weekly YYYY-MM-DD

Required environment variables:
    OBSIDIAN_SUMMARY_SMTP_USER  Gmail address used for SMTP login
    OBSIDIAN_SUMMARY_SMTP_PASS  Google App Password (16 chars, no spaces)

Optional:
    OBSIDIAN_SUMMARY_MAIL_TO    Recipient address (default: SMTP_USER)
    OBSIDIAN_SUMMARY_MAIL_FROM  From address (default: SMTP_USER)

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

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
EXTRACT_SCRIPT = os.path.join(SCRIPT_DIR, "extract-summary.py")

SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 465


def fail(msg: str, code: int = 2) -> None:
    print(msg, file=sys.stderr)
    sys.exit(code)


def run_extract(mode: str, date_str: str) -> dict:
    res = subprocess.run(
        ["python3", EXTRACT_SCRIPT, mode, date_str],
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
    msg["From"] = formataddr(("Obsidian Summary", mail_from))
    msg["To"] = mail_to
    msg["Date"] = formatdate(localtime=True)
    msg["Message-ID"] = make_msgid(domain="obsidian-summary.local")
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

    smtp_user = os.environ.get("OBSIDIAN_SUMMARY_SMTP_USER", "").strip()
    smtp_pass = os.environ.get("OBSIDIAN_SUMMARY_SMTP_PASS", "").strip()
    if not smtp_user or not smtp_pass:
        fail(
            "環境変数 OBSIDIAN_SUMMARY_SMTP_USER / OBSIDIAN_SUMMARY_SMTP_PASS が未設定です。\n"
            "Google アカウントでアプリパスワードを生成し、~/.claude/settings.local.json の env に保存してください。"
        )
    mail_to = os.environ.get("OBSIDIAN_SUMMARY_MAIL_TO", smtp_user).strip()
    mail_from = os.environ.get("OBSIDIAN_SUMMARY_MAIL_FROM", smtp_user).strip()

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
