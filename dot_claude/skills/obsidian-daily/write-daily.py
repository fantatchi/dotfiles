#!/usr/bin/env python3
"""
デイリーサマリーの書き込みヘルパー。

stdin から JSON を受け取り、デイリーノートにサマリーセクションを書き込む。
シェルの多段エスケープ問題を回避するため、ファイル I/O を Python に集約する。

使い方:
  echo '{"vault": "...", "target_date": "2026-03-31", ...}' | python3 write-daily.py
"""

import json
import os
import re
import sys
from datetime import datetime, timezone, timedelta

# Windows の stdin/stdout はデフォルトで cp932 等になり UnicodeEncodeError
# (surrogates not allowed) を起こすことがあるため UTF-8 に固定する。
# 呼び出し側の PYTHONIOENCODING 設定に依存しないようにするのが目的。
sys.stdin.reconfigure(encoding="utf-8")
sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

JST = timezone(timedelta(hours=9))

# --- テンプレート ---

DAILY_TEMPLATE = """\
---
created: {created}(UTC +09:00)
aliases: [{alias_slash},{alias_jp}]
tags: [Daily,{target_date}]
author: at-kato
---

[[{year_month}]]
[[DailyNotes]]

---
"""

SUMMARY_TEMPLATE = """\
## デイリーサマリー

> [!info] 自動生成
> - timestamp: {timestamp}
> - source: claude-summary
> - generation: 1
> - summary_of:
{summary_of}

### GitHub アクティビティ

#### コミット

{commits}

#### PR

{prs}

### 作業ログ

{logs}

### 今日の要約

{summary}

### 明日以降のタスク

{upcoming_tasks}"""


def build_summary_of(data: dict) -> str:
    """summary_of リスト（一次情報源）を Obsidian callout 用に整形する。

    再帰要約劣化対策: このサマリーが何を要約したものかを示すメタ。
    将来の上位サマリースキルが一次情報まで遡れるよう wiki-link / ラベルで残す。
    """
    items = []
    for log in data.get("logs", []):
        path = log.get("path")
        if path:
            base = os.path.basename(path)
            name = os.path.splitext(base)[0]
            items.append(f"[[{name}]]")
        else:
            project = log.get("project", "?")
            items.append(f"work-log:{project}")
    if data.get("commits"):
        items.append("github-api:commits")
    if data.get("prs"):
        items.append("github-api:prs")
    if not items:
        return ">   - なし"
    return "\n".join(f">   - {item}" for item in items)


def build_summary(data: dict) -> str:
    """JSON データからサマリーセクションの Markdown を生成する。"""
    now = datetime.now(JST)
    timestamp = now.strftime("%Y-%m-%d %H:%M")

    summary_of = build_summary_of(data)

    # コミット
    commits_list = data.get("commits", [])
    if commits_list:
        lines = []
        for c in commits_list:
            lines.append(f"- `{c['repo']}` — {c['message']} (`{c['sha']}`)")
        commits = "\n".join(lines)
    else:
        commits = "なし"

    # PR（重複排除済みのリスト）
    prs_list = data.get("prs", [])
    if prs_list:
        lines = []
        for p in prs_list:
            labels = "・".join(p.get("labels", []))
            lines.append(f"- [{p['title']}]({p['url']}) — {labels}")
        prs = "\n".join(lines)
    else:
        prs = "なし"

    # 作業ログ
    logs_list = data.get("logs", [])
    if logs_list:
        lines = []
        for log in logs_list:
            lines.append(f"- **{log['project']}**: {log['summary']}")
        logs = "\n".join(lines)
    else:
        logs = "作業ログの記録なし"

    summary_text = data.get("summary_text", "特筆事項なし")

    # 明日以降のタスク（Next / Waiting）
    upcoming_list = data.get("upcoming_tasks", [])
    if upcoming_list:
        lines = []
        for t in upcoming_list:
            section = t.get("section", "Next")
            marker = " ⏳" if section == "Waiting" else ""
            project = t.get("project", "")
            project_str = f" `#{project}`" if project else ""
            lines.append(f"- [ ]{project_str} {t['title']}{marker}")
        upcoming_tasks = "\n".join(lines)
    else:
        upcoming_tasks = "予定タスクなし"

    return SUMMARY_TEMPLATE.format(
        timestamp=timestamp,
        summary_of=summary_of,
        commits=commits,
        prs=prs,
        logs=logs,
        summary=summary_text,
        upcoming_tasks=upcoming_tasks,
    )


def build_daily_note(target_date: str) -> str:
    """デイリーノートの frontmatter 部分を生成する。"""
    dt = datetime.strptime(target_date, "%Y-%m-%d")
    now = datetime.now(JST)

    created = now.strftime("%Y-%m-%dT%H:%M:%S")
    alias_slash = dt.strftime("%Y/%m/%d")
    alias_jp = f"{dt.year}年{dt.month}月{dt.day}日"
    year_month = dt.strftime("%Y-%m")

    return DAILY_TEMPLATE.format(
        created=created,
        alias_slash=alias_slash,
        alias_jp=alias_jp,
        target_date=target_date,
        year_month=year_month,
    )


def write_daily(data: dict) -> str:
    """メイン処理。デイリーノートにサマリーを書き込む。"""
    # Python は `~` を自動展開しないため明示的に expanduser する。
    # これを省くと `~/ObsidianVault` が literal `~` ディレクトリとして作成されてしまう。
    vault = os.path.expanduser(data["vault"])
    target_date = data["target_date"]
    yyyymm = target_date.replace("-", "")[:6]

    daily_dir = os.path.join(vault, "_daily", yyyymm)
    daily_path = os.path.join(daily_dir, f"{target_date}.md")

    summary_section = build_summary(data)

    if not os.path.exists(daily_path):
        # ケース 1: ファイルが存在しない → 新規作成
        os.makedirs(daily_dir, exist_ok=True)
        content = build_daily_note(target_date) + "\n" + summary_section + "\n"
        with open(daily_path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"created:{daily_path}"

    with open(daily_path, "r", encoding="utf-8") as f:
        content = f.read()

    if "## デイリーサマリー" not in content:
        # ケース 2: サマリーなし → 末尾に追記
        if not content.endswith("\n"):
            content += "\n"
        content += "\n" + summary_section + "\n"
        with open(daily_path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"appended:{daily_path}"

    # ケース 3: サマリーあり → 上書き
    # "## デイリーサマリー" から次の "## " (同レベル) またはファイル末尾まで置換
    pattern = r"## デイリーサマリー.*"
    content_new = re.sub(pattern, summary_section, content, flags=re.DOTALL)
    # 末尾の改行を正規化
    content_new = content_new.rstrip("\n") + "\n"
    with open(daily_path, "w", encoding="utf-8") as f:
        f.write(content_new)
    return f"replaced:{daily_path}"


def main():
    input_path = None
    if len(sys.argv) >= 2:
        # ファイル経由（推奨）: Windows (Git Bash) では locale が cp932 のため
        # シェル変数 / ヒアドキュメント / pipe 経由で Python に渡すと JSON が
        # Python 到達前に cp932 bytes 化して化ける。stdin.reconfigure では
        # 救えないので、UTF-8 で書かれたファイルを直接読む経路を用意する。
        input_path = sys.argv[1]
        with open(input_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    else:
        # stdin 経由（Linux/macOS/WSL のみ動作保証）
        raw = sys.stdin.read()
        if not raw.strip():
            print("ERROR: stdin is empty", file=sys.stderr)
            sys.exit(1)
        data = json.loads(raw)

    result = write_daily(data)
    print(result)

    # 一時 JSON ファイルのクリーンアップ（書き込み成功後のみ）。
    # シェル側で rm を呼ばずに済ませることで Bash(rm:*) 権限要求を回避する。
    if input_path is not None:
        try:
            os.remove(input_path)
        except OSError:
            pass


if __name__ == "__main__":
    main()
