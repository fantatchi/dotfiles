#!/usr/bin/env python3
"""Extract '## デイリーサマリー' sections from Obsidian daily notes.

Usage:
    python3 extract-summary.py daily YYYY-MM-DD
    python3 extract-summary.py weekly YYYY-MM-DD   # 指定日を含む週（月〜日）

Output (stdout, JSON):
    {
        "mode": "daily" | "weekly",
        "target_date": "2026-05-12",                # daily の対象日
        "week_start": "2026-05-11",                  # weekly のみ
        "week_end":   "2026-05-17",                  # weekly のみ
        "available_dates": ["2026-05-12"],
        "missing_dates":   [],
        "empty": false,
        "subject": "[2026-05-12] デイリーサマリー",
        "body_markdown": "...整形済み本文..."
    }

Exit codes:
    0  正常（empty=true でもメール送信側で判断する）
    2  引数エラー
"""
from __future__ import annotations
import datetime as dt
import json
import os
import re
import sys

import markdown  # pip3 install --user markdown

VAULT = os.path.expanduser("~/ObsidianVault")
SECTION_HEADER = "## デイリーサマリー"

HTML_STYLE = """\
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Hiragino Kaku Gothic ProN', 'Yu Gothic UI', sans-serif; max-width: 720px; margin: 1em auto; padding: 0 1em; line-height: 1.6; color: #24292e; }
h1 { border-bottom: 2px solid #d0d7de; padding-bottom: .3em; margin-top: 0; }
h2 { border-bottom: 1px solid #d0d7de; padding-bottom: .3em; margin-top: 1.8em; }
h3 { margin-top: 1.4em; color: #1f2328; }
h4 { margin-top: 1em; color: #57606a; font-size: .95em; }
code { background: #f6f8fa; padding: .15em .4em; border-radius: 3px; font-family: 'SFMono-Regular', Consolas, monospace; font-size: .88em; }
pre { background: #f6f8fa; padding: 1em; border-radius: 6px; overflow-x: auto; }
blockquote { border-left: 4px solid #d0d7de; padding: .3em 1em; color: #57606a; margin-left: 0; background: #f6f8fa; border-radius: 0 6px 6px 0; }
blockquote.callout-info { border-left-color: #0969da; background: #ddf4ff; color: #0969da; }
ul { padding-left: 1.5em; }
li { margin: .2em 0; }
a { color: #0969da; text-decoration: none; }
a:hover { text-decoration: underline; }
hr { border: none; border-top: 1px solid #d0d7de; margin: 2em 0; }
"""


def md_to_html(md_text: str) -> str:
    """Convert Markdown (with Obsidian-style callouts) to a styled HTML document."""
    # Obsidian callout `> [!type] title` を blockquote の冒頭ラベルに変換
    def callout_repl(match: "re.Match[str]") -> str:
        ctype = match.group(1).lower()
        title = match.group(2).strip() or ctype.upper()
        return f"> **ℹ️ {title}**"

    transformed = re.sub(
        r"^>\s*\[!(\w+)\]\s*(.*)$",
        callout_repl,
        md_text,
        flags=re.MULTILINE,
    )
    body_html = markdown.markdown(
        transformed,
        extensions=["extra", "sane_lists", "nl2br"],
    )
    return (
        "<!DOCTYPE html>\n"
        '<html lang="ja"><head><meta charset="utf-8">'
        f"<style>{HTML_STYLE}</style></head>"
        f"<body>{body_html}</body></html>"
    )


def daily_note_path(target: dt.date) -> str:
    yyyymm = target.strftime("%Y%m")
    fname = target.strftime("%Y-%m-%d.md")
    return os.path.join(VAULT, "_daily", yyyymm, fname)


def extract_section(md: str) -> str | None:
    """Return the '## デイリーサマリー' section body (excluding the header)
    up to the next '## ' header or EOF. None if header not found.
    """
    lines = md.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.strip() == SECTION_HEADER:
            start = i + 1
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start, len(lines)):
        if lines[j].startswith("## ") and lines[j].strip() != SECTION_HEADER:
            end = j
            break
    body = "\n".join(lines[start:end]).strip()
    return body


def read_summary(target: dt.date) -> str | None:
    path = daily_note_path(target)
    if not os.path.isfile(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        md = f.read()
    return extract_section(md)


def build_daily(target: dt.date) -> dict:
    section = read_summary(target)
    available = [target.isoformat()] if section else []
    missing = [] if section else [target.isoformat()]
    empty = section is None
    subject = f"[{target.isoformat()}] デイリーサマリー"
    if empty:
        body = (
            f"# {target.isoformat()} のデイリーサマリー\n\n"
            f"対象日のサマリーセクションが見つかりませんでした。\n"
            f"想定パス: `~/ObsidianVault/_daily/{target.strftime('%Y%m')}/{target.isoformat()}.md`\n"
        )
    else:
        body = (
            f"# {target.isoformat()} のデイリーサマリー\n\n"
            f"{section}\n"
        )
    return {
        "mode": "daily",
        "target_date": target.isoformat(),
        "available_dates": available,
        "missing_dates": missing,
        "empty": empty,
        "subject": subject,
        "body_markdown": body,
        "body_html": md_to_html(body),
    }


def week_range(any_day: dt.date) -> tuple[dt.date, dt.date]:
    """Return (monday, sunday) of the week containing any_day."""
    monday = any_day - dt.timedelta(days=any_day.weekday())
    sunday = monday + dt.timedelta(days=6)
    return monday, sunday


def build_weekly(any_day: dt.date) -> dict:
    monday, sunday = week_range(any_day)
    days = [monday + dt.timedelta(days=i) for i in range(7)]
    available: list[str] = []
    missing: list[str] = []
    parts: list[str] = []
    for d in days:
        s = read_summary(d)
        if s is None:
            missing.append(d.isoformat())
            continue
        available.append(d.isoformat())
        weekday = "月火水木金土日"[d.weekday()]
        parts.append(f"## {d.isoformat()}（{weekday}）\n\n{s}\n")
    empty = len(available) == 0
    subject = f"[{monday.isoformat()}〜{sunday.isoformat()}] 週次サマリー（{len(available)}/7 日分）"
    if empty:
        body = (
            f"# {monday.isoformat()} 〜 {sunday.isoformat()} の週次サマリー\n\n"
            f"対象期間内のデイリーサマリーが 1 件も見つかりませんでした。\n"
        )
    else:
        miss_note = ""
        if missing:
            miss_note = f"\n> [!info] 欠落日: {', '.join(missing)}\n\n"
        body = (
            f"# {monday.isoformat()} 〜 {sunday.isoformat()} の週次サマリー\n\n"
            f"取得済み: {len(available)}/7 日分\n"
            f"{miss_note}"
            + "\n".join(parts)
        )
    return {
        "mode": "weekly",
        "week_start": monday.isoformat(),
        "week_end": sunday.isoformat(),
        "available_dates": available,
        "missing_dates": missing,
        "empty": empty,
        "subject": subject,
        "body_markdown": body,
        "body_html": md_to_html(body),
    }


def parse_date(s: str) -> dt.date:
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
        raise ValueError(f"日付は YYYY-MM-DD 形式で指定してください: {s!r}")
    return dt.date.fromisoformat(s)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    mode = argv[1]
    if mode not in ("daily", "weekly"):
        print(f"mode は daily / weekly のいずれか: {mode!r}", file=sys.stderr)
        return 2
    try:
        target = parse_date(argv[2])
    except ValueError as e:
        print(str(e), file=sys.stderr)
        return 2
    result = build_daily(target) if mode == "daily" else build_weekly(target)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
