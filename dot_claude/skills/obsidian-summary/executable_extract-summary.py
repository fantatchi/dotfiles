#!/usr/bin/env python3
"""Extract & restructure '## デイリーサマリー' sections into a readable email body.

Usage:
    python3 extract-summary.py daily YYYY-MM-DD
    python3 extract-summary.py weekly YYYY-MM-DD   # 指定日を含む週（月〜日）

Output (stdout, JSON):
    {
        "mode": "daily" | "weekly",
        "target_date": "2026-05-12",
        "week_start": "2026-05-11",
        "week_end":   "2026-05-17",
        "available_dates": ["2026-05-12"],
        "missing_dates":   [],
        "empty": false,
        "subject": "[2026-05-12] 日報",
        "body_markdown": "...再構成済み本文...",
        "body_html": "...HTML 整形済み..."
    }

設計:
    daily ノートの「## デイリーサマリー」セクションをパースし、
    メール向けに「ひとこと / ハイライト / GitHub / 明日のタスク」へ再構成する。
    元のフォーマット仕様（obsidian-daily が出力する形）に依存する。

Exit codes:
    0  正常（empty=true でも 0）
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
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Hiragino Kaku Gothic ProN', 'Yu Gothic UI', sans-serif; max-width: 720px; margin: 1em auto; padding: 0 1em; line-height: 1.65; color: #24292e; }
h1 { font-size: 1.6em; border-bottom: 2px solid #d0d7de; padding-bottom: .3em; margin: 0 0 1em; }
h2 { font-size: 1.2em; color: #0969da; border-left: 4px solid #0969da; padding: .1em .6em; margin: 2em 0 .8em; background: #f6f8fa; border-radius: 0 4px 4px 0; }
h3 { margin-top: 1.4em; color: #1f2328; font-size: 1.05em; }
p { margin: .6em 0; }
.tldr { background: #ddf4ff; border-left: 4px solid #0969da; padding: .8em 1em; border-radius: 0 6px 6px 0; margin: .6em 0 1.4em; }
.tldr p { margin: .3em 0; }
code { background: #f6f8fa; padding: .15em .4em; border-radius: 3px; font-family: 'SFMono-Regular', Consolas, monospace; font-size: .88em; }
ul { padding-left: 1.4em; margin: .6em 0; }
li { margin: .3em 0; }
li strong { color: #1f2328; }
a { color: #0969da; text-decoration: none; }
a:hover { text-decoration: underline; }
.meta { color: #57606a; font-size: .9em; margin: .2em 0 1.2em; }
.note { color: #57606a; font-size: .9em; font-style: italic; }
hr { border: none; border-top: 1px solid #d0d7de; margin: 2.4em 0; }
"""


# ---------- Parser ----------------------------------------------------------

def daily_note_path(target: dt.date) -> str:
    yyyymm = target.strftime("%Y%m")
    fname = target.strftime("%Y-%m-%d.md")
    return os.path.join(VAULT, "_daily", yyyymm, fname)


def extract_section(md: str) -> str | None:
    """Return body of '## デイリーサマリー' (excluding header) up to next '## '."""
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
    return "\n".join(lines[start:end]).strip()


def strip_meta_callout(body: str) -> str:
    """Remove leading auto-generated callout block.

    obsidian-daily が生成する `> [!info] 自動生成 ...` callout を冒頭から落とす。
    規約上「## デイリーサマリー」セクションの先頭にあるのは自動生成 callout のみ
    なので、「先頭の空行 + 連続する `>` 行」を一括で skip すれば十分。
    手書きの callout が先頭に混ざる運用は想定しない（規約縛り）。
    """
    lines = body.splitlines()
    i = 0
    # 先頭の空行をスキップ
    while i < len(lines) and not lines[i].strip():
        i += 1
    # 先頭が callout（`>` 始まり）なら連続する行をすべて skip
    while i < len(lines) and lines[i].startswith(">"):
        i += 1
    return "\n".join(lines[i:]).strip()


def split_by_h3(body: str) -> dict[str, str]:
    """Split body into a dict keyed by '### {name}'."""
    sections: dict[str, str] = {}
    cur_name: str | None = None
    cur_lines: list[str] = []
    for line in body.splitlines():
        m = re.match(r"^###\s+(.+?)\s*$", line)
        if m:
            if cur_name is not None:
                sections[cur_name] = "\n".join(cur_lines).strip()
            cur_name = m.group(1).strip()
            cur_lines = []
        else:
            cur_lines.append(line)
    if cur_name is not None:
        sections[cur_name] = "\n".join(cur_lines).strip()
    return sections


_BULLET_RE = re.compile(r"^\s*-\s*\*\*([^*]+)\*\*\s*[:：]\s*(.+)$")


def parse_worklog(text: str) -> list[dict]:
    """Parse `- **project**: body` bullets."""
    out: list[dict] = []
    for line in text.splitlines():
        m = _BULLET_RE.match(line)
        if m:
            out.append({"project": m.group(1).strip(), "body": m.group(2).strip()})
    return out


def first_sentence(text: str) -> str:
    """Return first sentence ending in '。' (else the full text)."""
    m = re.match(r"^(.+?。)", text)
    return m.group(1).strip() if m else text.strip()


GH_SUBSECTION_COMMITS = "コミット"
GH_SUBSECTION_PRS = "PR"


def parse_github(text: str) -> tuple[list[str], list[dict]]:
    """Parse '#### コミット' / '#### PR' subsections under '### GitHub アクティビティ'."""
    commits: list[str] = []
    prs: list[dict] = []
    current: str | None = None
    pr_link_re = re.compile(r"\[([^\]]+)\]\(([^)]+)\)\s*[—-]\s*(.+)$")
    for raw in text.splitlines():
        s = raw.rstrip()
        if s.startswith("#### "):
            head = s[5:].strip()
            if head.startswith(GH_SUBSECTION_COMMITS):
                current = "commits"
            elif head.startswith(GH_SUBSECTION_PRS):
                current = "prs"
            else:
                current = None
            continue
        if not s.lstrip().startswith("- "):
            continue
        bullet = s.lstrip()[2:].strip()
        if current == "commits":
            commits.append(bullet)
        elif current == "prs":
            m = pr_link_re.search(bullet)
            if not m:
                continue
            title = m.group(1).strip()
            url = m.group(2).strip()
            kind = m.group(3).strip()
            if "作成" in kind and "マージ" in kind:
                typ = "authored_merged"
            elif "作成" in kind:
                typ = "authored"
            elif "マージ" in kind:
                typ = "merged"
            elif "レビュー" in kind:
                typ = "review"
            else:
                typ = "other"
            prs.append({"title": title, "url": url, "kind": kind, "type": typ})
    return commits, prs


_TASK_RE = re.compile(
    r"^\s*-\s*\[\s*\]\s*"            # - [ ]
    r"`?#([A-Za-z0-9_/-]+)`?\s+"      # `#project` or #project
    r"(.+?)\s*$"
)


def parse_tasks(text: str) -> list[dict]:
    """Parse `- [ ] #project body` lines."""
    out: list[dict] = []
    for line in text.splitlines():
        m = _TASK_RE.match(line)
        if not m:
            continue
        # `lstrip("project/")` は文字集合扱いになって誤動作するため、startswith で個別処理
        proj = m.group(1).strip()
        if proj.startswith("project/"):
            proj = proj[len("project/"):]
        body = m.group(2).strip()
        # 末尾 ⏳ や @waiting マーカー判定
        waiting = ("@waiting" in body) or body.endswith("⏳")
        # 末尾 ⏳ は表示時に外す
        body_clean = body.rstrip()
        if body_clean.endswith("⏳"):
            body_clean = body_clean[:-1].rstrip()
        out.append({"project": proj, "body": body_clean, "waiting": waiting})
    return out


def strip_wikilinks(text: str) -> str:
    """Remove Obsidian internal links `[[...]]` (keep alias if `[[link|alias]]`)."""
    def repl(m: "re.Match[str]") -> str:
        inner = m.group(1)
        if "|" in inner:
            return inner.split("|", 1)[1]
        return inner
    return re.sub(r"\[\[([^\]]+)\]\]", repl, text)


def parse_summary(body: str) -> dict:
    """Top-level parser for a daily summary section body."""
    cleaned = strip_meta_callout(body)
    cleaned = strip_wikilinks(cleaned)
    sections = split_by_h3(cleaned)
    tldr = sections.get("今日の要約", "").strip()
    # 複数段落あれば最初の段落のみ採用（メールでは要約 1 段落で十分。
    # 残りを残すと HTML 後処理で .tldr ボックス外にこぼれてレイアウトが崩れる）
    if "\n\n" in tldr:
        tldr = tldr.split("\n\n", 1)[0].strip()
    worklog = parse_worklog(sections.get("作業ログ", ""))
    commits, prs = parse_github(sections.get("GitHub アクティビティ", ""))
    tasks = parse_tasks(sections.get("明日以降のタスク", ""))
    return {
        "tldr": tldr,
        "worklog": worklog,
        "gh_commits": commits,
        "gh_prs": prs,
        "tasks": tasks,
    }


# ---------- Renderer --------------------------------------------------------

def render_github(commits: list[str], prs: list[dict]) -> list[str]:
    if not commits and not prs:
        return []
    out = ["## GitHub", ""]
    n_authored = sum(1 for p in prs if p["type"] in ("authored", "authored_merged"))
    n_merged = sum(1 for p in prs if p["type"] in ("merged", "authored_merged"))
    n_review = sum(1 for p in prs if p["type"] == "review")
    summary_bits = [f"コミット {len(commits)} / PR {len(prs)}"]
    detail_bits = []
    if n_authored:
        detail_bits.append(f"作成 {n_authored}")
    if n_merged:
        detail_bits.append(f"マージ {n_merged}")
    if n_review:
        detail_bits.append(f"レビュー {n_review}")
    if detail_bits:
        summary_bits.append(f"（{', '.join(detail_bits)}）")
    out.append("".join(summary_bits))
    out.append("")
    for p in prs:
        out.append(f"- [{p['title']}]({p['url']}) — {p['kind']}")
    out.append("")
    return out


MAX_TASKS_IN_DAILY = 5  # 日報「明日のタスク」セクションの抜粋件数


def render_tasks(tasks: list[dict], top_n: int = MAX_TASKS_IN_DAILY) -> list[str]:
    active = [t for t in tasks if not t["waiting"]]
    waiting = [t for t in tasks if t["waiting"]]
    if not active and not waiting:
        return []
    out = [f"## 明日のタスク（{len(active)} 件）", ""]
    # プロジェクト別内訳（多い順）
    counts: dict[str, int] = {}
    for t in active:
        counts[t["project"]] = counts.get(t["project"], 0) + 1
    if counts:
        items = sorted(counts.items(), key=lambda x: (-x[1], x[0]))
        breakdown = " / ".join(f"{p} {n}" for p, n in items)
        out.append(f"プロジェクト別: {breakdown}")
        out.append("")
    for t in active[:top_n]:
        out.append(f"- `#{t['project']}` {t['body']}")
    rest = len(active) - top_n
    if rest > 0:
        out.append(f"- …ほか {rest} 件")
    if waiting:
        out.append("")
        out.append(f"_待ち {len(waiting)} 件は省略_")
    out.append("")
    return out


def render_daily_body(target: dt.date, parsed: dict) -> str:
    parts: list[str] = []
    weekday = "月火水木金土日"[target.weekday()]
    parts.append(f"# {target.isoformat()}（{weekday}）日報")
    parts.append("")
    if parsed["tldr"]:
        parts.append("## 今日のひとこと")
        parts.append("")
        parts.append(parsed["tldr"])
        parts.append("")
    if parsed["worklog"]:
        parts.append(f"## ハイライト（{len(parsed['worklog'])} プロジェクト）")
        parts.append("")
        for w in parsed["worklog"]:
            parts.append(f"- **{w['project']}** — {first_sentence(w['body'])}")
        parts.append("")
    parts.extend(render_github(parsed["gh_commits"], parsed["gh_prs"]))
    parts.extend(render_tasks(parsed["tasks"]))
    return "\n".join(parts).rstrip() + "\n"


MAX_BULLETS_PER_PROJECT = 3  # 週報「プロジェクト別ハイライト」の各プロジェクト最大表示件数


def render_weekly_body(monday: dt.date, sunday: dt.date,
                       day_entries: list[dict], missing: list[str]) -> str:
    parts: list[str] = []
    parts.append(f"# {monday.isoformat()} 〜 {sunday.isoformat()} 週報")
    parts.append("")
    if missing:
        parts.append(f"取得済み: {len(day_entries)}/7 日分（欠落: {', '.join(missing)}）")
    else:
        parts.append(f"取得済み: {len(day_entries)}/7 日分")
    parts.append("")

    # プロジェクト別に worklog bullets を集約
    proj_bullets: dict[str, list[dict]] = {}
    for entry in day_entries:
        d: dt.date = entry["date"]
        for w in entry["parsed"]["worklog"]:
            proj = w["project"]
            proj_bullets.setdefault(proj, []).append({
                "date": d,
                "summary": first_sentence(w["body"]),
            })

    # 集計
    total_commits = sum(len(d["parsed"]["gh_commits"]) for d in day_entries)
    total_prs = sum(len(d["parsed"]["gh_prs"]) for d in day_entries)
    total_tasks = sum(
        len([t for t in d["parsed"]["tasks"] if not t["waiting"]])
        for d in day_entries
    )
    parts.append("## 週次集計")
    parts.append("")
    parts.append(f"- 動いたプロジェクト: {len(proj_bullets)}")
    parts.append(f"- GitHub: コミット {total_commits} / PR {total_prs}")
    parts.append(f"- 明日タスク累計: {total_tasks} 件")
    parts.append("")

    # プロジェクト別ハイライト（活動件数の多い順）
    if proj_bullets:
        parts.append("## プロジェクト別ハイライト")
        parts.append("")
        proj_sorted = sorted(
            proj_bullets.items(),
            key=lambda x: (-len(x[1]), x[0]),
        )
        for proj, bullets in proj_sorted:
            parts.append(f"### {proj} · {len(bullets)} 件")
            parts.append("")
            for b in bullets[:MAX_BULLETS_PER_PROJECT]:
                mmdd = b["date"].strftime("%m-%d")
                parts.append(f"- [{mmdd}] {b['summary']}")
            rest = len(bullets) - MAX_BULLETS_PER_PROJECT
            if rest > 0:
                parts.append(f"- …ほか {rest} 件")
            parts.append("")

    return "\n".join(parts).rstrip() + "\n"


# ---------- HTML conversion -------------------------------------------------

def md_to_html(md_text: str) -> str:
    body_html = markdown.markdown(
        md_text,
        extensions=["extra", "sane_lists"],
    )
    # h2「今日のひとこと」直後の <p>...</p> に class を付与して青ボックス化。
    # re.DOTALL は parse_summary で 1 段落に絞っているはずでも、markdown が段落内改行を
    # <p>...\n...</p> のように展開した場合に拾えるよう保険として残す。
    body_html = re.sub(
        r"(<h2>今日のひとこと</h2>)\s*<p>(.*?)</p>",
        r'\1<div class="tldr"><p>\2</p></div>',
        body_html,
        count=1,
        flags=re.DOTALL,
    )
    return (
        "<!DOCTYPE html>\n"
        '<html lang="ja"><head><meta charset="utf-8">'
        f"<style>{HTML_STYLE}</style></head>"
        f"<body>{body_html}</body></html>"
    )


# ---------- Public API ------------------------------------------------------

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
    subject = f"[{target.isoformat()}] 日報"
    if empty:
        body_md = (
            f"# {target.isoformat()} 日報\n\n"
            f"対象日のサマリーセクションが見つかりませんでした。\n\n"
            f"想定パス: `~/ObsidianVault/_daily/{target.strftime('%Y%m')}/{target.isoformat()}.md`\n"
        )
    else:
        parsed = parse_summary(section)
        body_md = render_daily_body(target, parsed)
    return {
        "mode": "daily",
        "target_date": target.isoformat(),
        "available_dates": available,
        "missing_dates": missing,
        "empty": empty,
        "subject": subject,
        "body_markdown": body_md,
        "body_html": md_to_html(body_md),
    }


def week_range(any_day: dt.date) -> tuple[dt.date, dt.date]:
    monday = any_day - dt.timedelta(days=any_day.weekday())
    sunday = monday + dt.timedelta(days=6)
    return monday, sunday


def build_weekly(any_day: dt.date) -> dict:
    monday, sunday = week_range(any_day)
    days = [monday + dt.timedelta(days=i) for i in range(7)]
    available: list[str] = []
    missing: list[str] = []
    entries: list[dict] = []
    for d in days:
        s = read_summary(d)
        if s is None:
            missing.append(d.isoformat())
            continue
        available.append(d.isoformat())
        entries.append({"date": d, "parsed": parse_summary(s)})
    empty = not entries
    subject = (
        f"[{monday.isoformat()}〜{sunday.isoformat()}] 週報"
        f"（{len(available)}/7 日分）"
    )
    if empty:
        body_md = (
            f"# {monday.isoformat()} 〜 {sunday.isoformat()} 週報\n\n"
            f"対象期間内のデイリーサマリーが 1 件も見つかりませんでした。\n"
        )
    else:
        body_md = render_weekly_body(monday, sunday, entries, missing)
    return {
        "mode": "weekly",
        "week_start": monday.isoformat(),
        "week_end": sunday.isoformat(),
        "available_dates": available,
        "missing_dates": missing,
        "empty": empty,
        "subject": subject,
        "body_markdown": body_md,
        "body_html": md_to_html(body_md),
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
