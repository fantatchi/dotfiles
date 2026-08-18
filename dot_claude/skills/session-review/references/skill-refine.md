# Phase 3: スキル洗練 詳細手順

## Step 1: 対象スキルの特定

以下のディレクトリからユーザー作成スキルを検索する:

```
# プロジェクトスコープ
.claude/skills/*/SKILL.md

# ユーザースコープ
~/.claude/skills/*/SKILL.md
```

**プラグインスキルは対象外。** ユーザーが自ら作成・管理しているスキルのみ扱う。

## Step 2: セッション内容からの改善点抽出

会話コンテキストを振り返り、以下を判定する。

**既存スキルの改善:**
- このセッションで使われたスキルの指示通りに動かなかった箇所はないか
- ユーザーが手動で補正・修正した手順はないか
- スキルに追加すべきエッジケースはないか
- トリガー条件（description）に漏れはないか

**新規スキル候補:**
- セッション中に繰り返し行ったワークフローはないか
- 汎用化できるパターンはないか
- 他のセッションでも再利用できそうな手順はないか

改善点も新規候補もなければこのフェーズをスキップ。

## Step 3: 提案の収集

Step 1〜2 の結果を SKILL.md 本体の一括提示フォーマットに渡す。
個別確認はしない（SKILL.md 本体で全フェーズまとめて1回確認する）。

## 適用時のルール

ユーザー承認後:

- **既存スキルの改善**: `Edit` で対象の SKILL.md を修正
- **新規スキルの作成**: `Write` で新しい SKILL.md を作成
  - 作成先をユーザーに確認（プロジェクト `.claude/skills/` or ユーザー `~/.claude/skills/`）
  - 最小限のSKILL.md（frontmatter + 基本構造）を生成

### 編集で終わらせない（chezmoi 反映｜MUST）

`~/.claude/skills/` 配下は **chezmoi 管理下の live を直接編集する**運用なので、`Edit` / `Write` だけで止めると
source と乖離し、**次の `chezmoi apply` で黙って巻き戻る**。手順とチェックリストは
[`~/.claude/docs/skill-management.md`](../../../docs/skill-management.md) の「chezmoi 反映」節が正本
（既存ファイルは `chezmoi re-add`、新規ファイルは `chezmoi add`、削除は source 側も削除）。
**編集と同一セッションで反映まで確認する。**

- **`chezmoi` が Windows シェルで見つからなくても「入っていない」と判断しない。** WSL 側にのみ
  インストールされている構成があり、その場合 `~/.claude/skills` は WSL パスへの symlink になっている
  ことがある（= 編集は最初から管理対象に入っている）。発見手順は
  [`~/.claude/docs/work-tips.md`](../../../docs/work-tips.md) の「WSL 側にしかない chezmoi に
  Windows ネイティブからアクセスする」
- **Windows の Python でファイルを書くと LF が CRLF に化ける**（`open(p, "w")` の既定）。
  chezmoi はバイト比較なので `chezmoi diff` が全文置換になる。`newline=""` を付けるか `wb` で書く
  （詳細は work-tips.md）
- 反映漏れは**後から発見される**: 2026-06-02 に `obsidian-daily/SKILL.md`、2026-08-16 に
  `context-save/SKILL.md` の手順追加が、いずれも live のみで source に入っていなかった
