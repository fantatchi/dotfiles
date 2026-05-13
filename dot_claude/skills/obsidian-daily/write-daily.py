#!/usr/bin/env python3
"""
デイリーサマリーの書き込みヘルパー。

stdin から JSON を受け取り、デイリーノートにサマリーセクションを書き込む。
シェルの多段エスケープ問題を回避するため、ファイル I/O を Python に集約する。

使い方:
  echo '{"vault": "...", "target_date": "2026-03-31", ...}' | python3 write-daily.py
"""
from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone, timedelta
from typing import TypedDict


class Commit(TypedDict, total=False):
    """1 コミットのレコード。`repo` は `owner/name` 形式。"""
    sha: str
    message: str
    repo: str


class PR(TypedDict, total=False):
    """1 PR のレコード。`labels` は ["作成", "マージ", "レビュー"] の任意組み合わせ。"""
    title: str
    url: str
    labels: list[str]


class Log(TypedDict, total=False):
    """1 作業ログのレコード。`path` は vault 相対パス、`summary_of` 展開に使う。"""
    path: str
    project: str
    summary: str


class Task(TypedDict, total=False):
    """tasks.md の 1 行を抽出したレコード。`section` は "Next" / "Waiting"。"""
    section: str
    project: str
    title: str


class SummaryInput(TypedDict, total=False):
    """write-daily.py が JSON で受け取る最上位ペイロード。"""
    vault: str
    target_date: str
    commits: list[Commit]
    prs: list[PR]
    logs: list[Log]
    upcoming_tasks: list[Task]
    summary_text: str

# Windows の stdin/stdout はデフォルトで cp932 等になり UnicodeEncodeError
# (surrogates not allowed) を起こすことがあるため UTF-8 に固定する。
# 呼び出し側の PYTHONIOENCODING 設定に依存しないようにするのが目的。
sys.stdin.reconfigure(encoding="utf-8")
sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

JST = timezone(timedelta(hours=9))

# PR breakdown 表示順（KPI 行の `(作成 N・マージ M・レビュー L)` の並び）。
# JSON で渡される labels は順不同のため、ここで表示順を確定する。
_PR_LABEL_ORDER: tuple[str, ...] = ("作成", "マージ", "レビュー")

# リポ別グルーピング時に「末尾固定」にするノイズリポの判定パターン。
# repo 名（owner/name 含む）の部分一致で判定する。auto-backup 系の大量
# コミットが「件数大」で上位に来てしまうのを防ぐ。
_NOISE_REPO_PATTERNS: tuple[str, ...] = ("vault", "backup")

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

{kpi_line}

> [!info]- 自動生成（メタデータ）
> - timestamp: {timestamp}
> - source: claude-summary
> - generation: 1
> - summary_of:
{summary_of}

### 今日の要約

{summary}

### GitHub アクティビティ

#### コミット

{commits}

#### PR

{prs}

### 作業ログ

{logs_section}

### 明日以降のタスク

{upcoming_tasks}"""


def build_kpi_line(data: SummaryInput) -> str:
    """概況 KPI 行を組み立てる（視線最上段に置く全体指標）。

    例: **今日の活動**: commits **27** (4 repos) / PRs **6** (作成 5・マージ 4) / logs **10**

    全件 0 でも行は出す（活動なし日であることが一目で分かる）。

    >>> build_kpi_line({"commits": [], "prs": [], "logs": []})
    '**今日の活動**: commits **0** / PRs **0** / logs **0**'
    >>> data = {
    ...     "commits": [{"sha": "a", "message": "m", "repo": "o/r1"},
    ...                 {"sha": "b", "message": "m", "repo": "o/r2"}],
    ...     "prs": [{"title": "t", "url": "u", "labels": ["作成", "マージ"]},
    ...             {"title": "t", "url": "u", "labels": ["レビュー"]}],
    ...     "logs": [{"project": "p", "summary": "s"}],
    ... }
    >>> build_kpi_line(data)
    '**今日の活動**: commits **2** (2 repos) / PRs **2** (作成 1・マージ 1・レビュー 1) / logs **1**'
    """
    commits = data.get("commits", [])
    prs = data.get("prs", [])
    logs = data.get("logs", [])

    repos = {c["repo"] for c in commits if c.get("repo")}
    n_commits = len(commits)
    repos_part = f" ({len(repos)} repos)" if repos else ""

    n_prs = len(prs)
    label_counts: dict[str, int] = {}
    for p in prs:
        for lbl in p.get("labels", []) or []:
            label_counts[lbl] = label_counts.get(lbl, 0) + 1
    if label_counts:
        breakdown_parts = [f"{k} {label_counts[k]}" for k in _PR_LABEL_ORDER if k in label_counts]
        for k, v in label_counts.items():
            if k not in _PR_LABEL_ORDER:
                breakdown_parts.append(f"{k} {v}")
        pr_str = f"**{n_prs}** ({'・'.join(breakdown_parts)})"
    else:
        pr_str = f"**{n_prs}**"

    return (
        f"**今日の活動**: commits **{n_commits}**{repos_part}"
        f" / PRs {pr_str}"
        f" / logs **{len(logs)}**"
    )


def _is_noise_repo(repo: str) -> bool:
    """リポ名が `_NOISE_REPO_PATTERNS` のいずれかを部分一致で含むなら True。"""
    lower = repo.lower()
    return any(p in lower for p in _NOISE_REPO_PATTERNS)


def build_grouped_commits(commits_list: list[Commit]) -> str:
    """コミットをリポジトリ軸でグルーピングして整形する。

    並び順:
      1. ノイズリポ（`_NOISE_REPO_PATTERNS` 該当）は末尾固定
      2. 非ノイズリポ間は件数大の順、同件数はリポ名昇順
      3. 同一リポ内は入力順（時系列）を保持

    各リポ別小見出しを出した上で、各コミット行からは repo prefix を除く（冗長排除）。

    >>> build_grouped_commits([])
    'なし'
    >>> # 件数大の順 + 同件数はアルファベット順 + vault は末尾固定
    >>> commits = [
    ...     {"sha": "v1", "message": "auto-backup", "repo": "o/obsidian-vault"},
    ...     {"sha": "a1", "message": "msg-a", "repo": "o/alpha"},
    ...     {"sha": "b1", "message": "msg-b1", "repo": "o/beta"},
    ...     {"sha": "b2", "message": "msg-b2", "repo": "o/beta"},
    ... ]
    >>> print(build_grouped_commits(commits))
    ##### o/beta (2)
    <BLANKLINE>
    - msg-b1 (`b1`)
    - msg-b2 (`b2`)
    <BLANKLINE>
    ##### o/alpha (1)
    <BLANKLINE>
    - msg-a (`a1`)
    <BLANKLINE>
    ##### o/obsidian-vault (1)
    <BLANKLINE>
    - auto-backup (`v1`)
    """
    if not commits_list:
        return "なし"

    by_repo: dict[str, list[Commit]] = {}
    for c in commits_list:
        repo = c.get("repo", "(unknown)")
        by_repo.setdefault(repo, []).append(c)

    # ソートキー: (is_noise, -count, name) — noise=False が先、件数大が先、名前昇順
    sorted_repos = sorted(
        by_repo.items(),
        key=lambda kv: (_is_noise_repo(kv[0]), -len(kv[1]), kv[0]),
    )

    parts: list[str] = []
    for repo, commits in sorted_repos:
        parts.append(f"##### {repo} ({len(commits)})")
        parts.append("")
        for c in commits:
            parts.append(f"- {c['message']} (`{c['sha']}`)")
        parts.append("")
    return "\n".join(parts).rstrip()


def build_logs_section(logs_list: list[Log]) -> str:
    """作業ログを「プロジェクト × 件数」フラットサマリー + collapsible callout で整形する。

    件数があるときは:
        1. 折り畳み**外**に「プロジェクト別件数: proj-A 4 / proj-B 2 / ...」の 1 行サマリー
           （PDF Export 時に折り畳み内が消える Obsidian の挙動と、forward 互換性の保険を兼ねる）
        2. `> [!note]- 詳細（作業ログ N 件）` callout の中に詳細 bullet（要約との重複を視覚階層で解消）
    0 件のときは plain text で「作業ログの記録なし」とする。

    >>> build_logs_section([])
    '作業ログの記録なし'
    >>> logs = [
    ...     {"project": "alpha", "summary": "s1"},
    ...     {"project": "alpha", "summary": "s2"},
    ...     {"project": "beta", "summary": "s3"},
    ... ]
    >>> print(build_logs_section(logs))
    プロジェクト別件数: alpha 2 / beta 1
    <BLANKLINE>
    > [!note]- 詳細（作業ログ 3 件）
    > - **alpha**: s1
    > - **alpha**: s2
    > - **beta**: s3
    """
    if not logs_list:
        return "作業ログの記録なし"

    counts: dict[str, int] = {}
    for log in logs_list:
        proj = log.get("project") or "(unknown)"
        counts[proj] = counts.get(proj, 0) + 1
    sorted_counts = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    breakdown = "プロジェクト別件数: " + " / ".join(f"{p} {n}" for p, n in sorted_counts)

    lines = [breakdown, "", f"> [!note]- 詳細（作業ログ {len(logs_list)} 件）"]
    for log in logs_list:
        lines.append(f"> - **{log['project']}**: {log['summary']}")
    return "\n".join(lines)


def build_summary_of(data: SummaryInput) -> str:
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


def build_summary(data: SummaryInput) -> str:
    """JSON データからサマリーセクションの Markdown を生成する。"""
    now = datetime.now(JST)
    timestamp = now.strftime("%Y-%m-%d %H:%M")

    summary_of = build_summary_of(data)
    kpi_line = build_kpi_line(data)

    # コミット（リポ軸でグルーピング、ノイズリポは末尾固定）
    commits = build_grouped_commits(data.get("commits", []))

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

    # 作業ログ（collapsible callout で畳む）
    logs_section = build_logs_section(data.get("logs", []))

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
        kpi_line=kpi_line,
        summary_of=summary_of,
        commits=commits,
        prs=prs,
        logs_section=logs_section,
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


def write_daily(data: SummaryInput) -> str:
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
