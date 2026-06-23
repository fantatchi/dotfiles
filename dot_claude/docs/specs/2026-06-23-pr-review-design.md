# /pr-review スキル 設計仕様

- 作成: 2026-06-23
- 場所: `~/.claude/skills/pr-review/SKILL.md`（個人グローバル）
- 関連: `~/.claude/skills/multi-persona-review/SKILL.md`（再利用元）
- 棲み分け対象: 公式 `/code-review`（plugin `claude-plugins-official`）

## 1. 目的

GitHub PR の URL（または番号）を渡したら以下を一気通貫で実施するオーケストレータスキル:

1. ブランチ切替・最新化
2. PR メタ + Copilot / discussion / inline コメント取得
3. ペルソナ案提示（**1 段承認**）
4. 並列レビュー（multi-persona-review プロセスを参照知識として再利用）
5. メインで実コード裏取り・severity 確定（MEMORY 運用ルール遵守）
6. `.claude/reviews/pr-{NNN}-{branch-key}-{YYYY-MM-DD}.md` への所見出力

**投稿はしない**（草稿のみ出力、過去 7 件運用と同じ）。

## 2. 公式 `/code-review` との棲み分け

| 項目 | 公式 `/code-review ultra <PR#>` | `/pr-review`（本スキル） |
|---|---|---|
| 出力先 | GitHub inline コメント投稿 | ローカル `.claude/reviews/` に草稿 |
| レビュー手法 | LLM 自動 + confidence scoring（80 閾値） | 3-5 ペルソナ並列 + メイン裏取り |
| 運用ルール | 公式デフォルト | ユーザー MEMORY 系（`feedback_pr_review_*`）を冒頭明示遵守 |
| `--fix` モード | あり（働く tree 適用） | なし（読取専用） |
| クラウド実行 | あり（cloud agent） | ローカル Agent 並列 |

トリガーが被るシーンでは description で差別化を明示し、LLM が文脈で判断できるようにする。

## 3. アーキテクチャ

### 3.1 フェーズ構成

```
[起動] /pr-review <PR URL or 番号>
   ↓
[Phase 1: 取得]
  - 現ブランチに**追跡対象の未コミット変更（modified / staged）**があれば中断 → ユーザー対処依頼
    （submodule 由来の untracked（`ks-react-components/` 等）は無視）
  - URL から repo + PR 番号抽出、または番号のみなら origin remote から repo 推定
  - git fetch origin <branch> <base>
  - git checkout <branch>（既に同ブランチなら skip）
  - git pull --ff-only origin <branch>
    - ff-only 失敗（コンフリクト・force-push 由来の divergence）→ 中断 → ユーザー対処依頼
  - gh pr view（メタ・既存レビュー）
  - gh api repos/{owner}/{repo}/pulls/{n}/comments（inline + Copilot）
  - gh api repos/{owner}/{repo}/issues/{n}/comments（discussion）
  - git diff --stat origin/{base}...HEAD（規模把握）
   ↓
[Phase 2: ペルソナ案提示]
  - PR 差分・性質から 3-5 体提案（後述 4 章の指針）
  - 各ペルソナの「専門領域 / 着眼点 / 担当ファイル群」を会話に提示
  - **AskUserQuestion** で承認/修正/追加を 1 アクションで聞く（テキストでの自由応答も可）
  - ★承認待ち★ — 修正指示があれば反映してもう一度提示
   ↓
[Phase 3: 並列レビュー]
  - multi-persona-review/SKILL.md を Read で参照
  - Agent (subagent_type=general-purpose) を並列起動
  - 各 prompt にペルソナ定義 + PR 文脈 + 5-6 個の番号付き質問 + 500-800 字制限
   ↓
[Phase 4: 裏取り・統合]
  - メインで各所見を実コード grep / Read で裏取り
  - MEMORY feedback_pr_review_* に従い偽陽性・speculation 除外
  - severity 確定（CRITICAL / HIGH / MIDDLE / LOW）
  - Copilot 既出指摘との突合
   ↓
[Phase 5: 所見出力]
  - `.claude/reviews/pr-{NNN}-{branch-key-snippet}-{YYYY-MM-DD}.md` へ Write
  - 既存テンプレ準拠（過去 7 件と同構造、6 章テンプレ）
  - ファイルパスを会話で提示
  - **context.md / tasks.md は触らない**（ユーザーが /context-save / /gtd-* で別途管理）
  - **投稿可否は聞かない**（ユーザー判断、必要なら別途「投稿用整形」依頼可）
  - 元のブランチへの復帰は**しない**（Q2 の決定 = checkout のみ、復帰なし）
```

### 3.2 引数バリエーション

- `/pr-review https://github.com/<owner>/<repo>/pull/<NNN>` — 完全 URL
- `/pr-review <NNN>` — 番号のみ（origin remote から repo 推定）
- `/pr-review <owner>/<repo>#<NNN>` — gh 標準形式

未対応（将来検討）:
- `/pr-review --personas 'A,B,C'` で承認スキップ → YAGNI、必要になったら追加

## 4. ペルソナ自動生成の指針

LLM 裁量を残しつつ、SKILL.md に**選定指針**を明示する。既定セットは持たない（PR 文脈で具体化する方が効果的）。

### 4.1 ファイル種別 → 専門領域マッピング

| 差分ファイル種別 | 専門領域候補 |
|---|---|
| `*.tsx` / `*.ts`（React） | React 状態管理 / 型安全 / UX・バリデーション / アクセシビリティ |
| `*.cs`（ASP.NET Core） | VSA Endpoint 設計 / EF Core クエリ / セキュリティ / DI |
| `*.test.ts` / `*.spec.ts` 主体 | テスト設計・カバレッジ・実効性 |
| `*.scss` / `*.css` | CSS 回帰・layer 境界・デザイントークン整合 |
| `*.yml`（CI/Actions） | CI/CD 設計・secrets 取り回し・キャッシュ |
| `package.json` / `package-lock.json` | 依存サプライチェーン・peer dep・脆弱性 |
| `*.sql` / `migrations/` | スキーマ進化・データ移行・破壊的変更 |
| Route Handler (`app/api/`) | BFF 境界・認可・proxy 経路 |

### 4.2 PR 性質マーカー

タイトル・本文から導出:

- `fix(` — バグ修正中心 → ロジック整合・回帰観点強化
- `feat(` — 新機能 → UX・データ整合・テストカバレッジ
- `refactor(` — 内部構造変更 → **挙動保存検証**を最重視
- `chore(deps)` — 依存更新 → 破壊的変更・peer dep・サプライチェーン
- `perf(` — パフォーマンス → ベンチ・回帰
- `style(` / フォーマット — レビュー価値低、3 体最小構成

### 4.3 PR 規模による体数調整

| 規模（差分行数） | 既定体数 |
|---|---|
| < 300 | 3 体 |
| 300 - 1000 | 4 体 |
| > 1000 | 5 体 |

ただし規模 < 100 で機械的変更（フォーマットのみ等）なら**ペルソナ不要・短評**を提案する選択肢を残す。

### 4.4 multi-persona-review のペルソナ典型例を PR 文脈で具体化

| 典型 | PR 文脈での具体化例 |
|---|---|
| シニア開発 | 「React 状態管理 / Jotai + TanStack Query 規約」 |
| セキュリティ | 「Next.js Route Handler の認可境界 / Auth.js v5 JWT 経路」 |
| テスト設計 | 「Vitest + MSW / カバレッジ実効性 / エッジ網羅」 |
| アクセシビリティ | **省略可**（MEMORY `feedback_pr_review_screen_reader` で SR 系除外運用） |

## 5. MEMORY 運用ルール遵守の組み込み

Phase 4（裏取り・統合）の冒頭で以下を**明示参照**する（参照誘導なしだと LLM が読み飛ばすため）:

- `[[feedback_pr_review_screen_reader]]` — SR 系指摘は省略
- `[[feedback_useMemo_no_speculative]]` — 計測なし useMemo を HIGH に上げない
- `[[feedback_pr_review_speculative_defense]]` — 発生しないシナリオの防御コードを HIGH に上げない
- `[[feedback_pr_review_mock_temporary]]` — BE 未実装 mock の構造指摘は見送る
- `[[feedback_pr_review_verify_before_severity]]` — ペルソナ指摘は前提裏取りしてから severity 確定
- `[[feedback_commit_one_per_sonarqube_finding]]` — 静的解析対応の粒度
- `[[feedback_quality_gate_wording]]` — Quality Gate を「緑化」と言わない
- `[[feedback_force_push_repo_workflow]]` — 別 PR のファイルはその PR ブランチへ直接コミット

これらは MEMORY.md 経由で常時注入されているが、レビュー文脈では特に踏み外しやすいので SKILL.md で**明示再注意**する。

## 6. 所見ファイル構造

`.claude/reviews/pr-{NNN}-{branch-key-snippet}-{YYYY-MM-DD}.md`

- `{NNN}` — PR 番号（ゼロパディングなし）
- `{branch-key-snippet}` — ブランチ名の最後のセグメント（`pr/sh-watanabe/feat_photoPlaceListDialog` → `photoPlaceListDialog`）
- `{YYYY-MM-DD}` — レビュー実施日

テンプレート（過去 7 件 + 直近 #444/#462 と同構造）:

```markdown
# PR #{NNN} レビュー所見

- 対象 / タイトル / author / base / 規模 / 状態 / レビュー日

## スコープ
## 結論（CRITICAL / HIGH 件数を冒頭明示）
## 検証（pass したテスト・grep 結果・確認した実装位置）
## 確定指摘
### CRITICAL: ...
### HIGH: ...
### MIDDLE: ...
### LOW: ...
## Copilot N 件の評価
## 良い点
## メモ
```

## 7. SKILL.md frontmatter

```yaml
---
name: pr-review
description: GitHub PR の URL または番号を渡すと、ブランチ切替・最新化、Copilot/discussion コメント取得、3-5 体のペルソナ並列レビュー、メインでの実コード裏取り、ローカル `.claude/reviews/` への所見草稿出力までを一気通貫で実施するオーケストレータスキル。投稿はしない（草稿のみ）。「PR レビュー」「pr/<番号> をレビュー」「<PR URL> を見て」「PR の差分どう」「<番号> 番見て」「これマージしていい？」「PR の感想」「ペルソナで PR 見て」等の依頼で発動。公式 `/code-review ultra <PR#>` も PR 自動レビュー機能を持つが、本スキルは (a) インライン投稿せず `.claude/reviews/` に草稿のみ出力 (b) ペルソナ並列で観点分割 (c) ユーザーの MEMORY 運用ルール（SR 系除外・useMemo speculation 抑制・防御コード speculation 抑制等）を冒頭明示遵守 の点で異なる。投稿前提なら公式、ローカル草稿・ペルソナ・運用ルール反映なら本スキル。
argument-hint: <PR URL or PR番号>
allowed-tools: Agent, Read, Glob, Grep, Bash(git:*), Bash(gh:*), Write
---
```

## 8. SKILL.md 本文の章立て（draft 予定）

1. このスキルが解く問題（30 行）
2. 使うべき時 / 使うべきでない時（20 行）
3. 公式 `/code-review` との棲み分け（15 行）
4. 実行手順 Phase 1-5（150 行）
5. ペルソナ自動生成の指針（60 行）
6. MEMORY 遵守の明示参照（30 行）
7. よくある失敗と回避策（30 行）
8. 関連スキル（10 行）

合計推定 ~345 行（500 行ガイドライン内）。500 行近づいたら `references/persona-selection.md`（4.1-4.4 章）と `references/output-template.md`（6 章）を分離。

## 9. CLAUDE.md / README 反映

skill-management.md チェックリスト遵守:

- [ ] `~/.claude/CLAUDE.md` の「# スキルコマンド」セクション > レビュー行を更新:
  - 軽量並列観点= `/multi-persona-review`（既存）
  - **PR フル自動=`/pr-review`（追加）**
- [ ] `~/.local/share/chezmoi/README.md` のスキル一覧テーブルに 1 行追加
- [ ] `chezmoi add ~/.claude/skills/pr-review/SKILL.md`
- [ ] `chezmoi diff` で残差確認
- [ ] スキル本体追加・CLAUDE.md 反映・README 反映を **1 コミットで揃える**

## 10. テストケース（draft 後実施）

| ID | シナリオ | 期待動作 |
|---|---|---|
| T1 | cloud-cmp 小型 PR（< 300 行）`/pr-review <URL>` | 3 体ペルソナ提案 → 承認 → 並列 → 所見ファイル出力 |
| T2 | cloud-cmp 大型 PR（> 1000 行）`/pr-review <URL>` | 5 体ペルソナ提案 → 承認 → 並列 → 所見ファイル出力 |
| T3 | 番号のみ起動 `/pr-review 462` | origin remote から repo 推定 → 通常フロー |
| T4 | 既に checkout 済の同ブランチで起動 | pull --ff-only だけ走って続行 |
| T5 | 未コミット変更ありで起動 | 中断 → ユーザーに対処依頼 |

評価方針: 主観評価寄り（PR レビューは LLM 裁量大）なので、quantitative assertions より「過去 7 件の所見ファイル（`.claude/reviews/pr-*-2026-06-*.md`）と粒度・構造が揃うか」を qualitative に判定。

## 11. 残課題 / 将来拡張

- **`--personas '...'` で承認スキップ**: YAGNI、必要になったら追加
- **worktree モード**: cloud-cmp の submodule + node_modules 問題でメリット薄、将来別ユースケースで必要なら検討
- **MEMORY 遵守 references 化**: 該当 feedback memory が増えたら references で参照表化
- **複数 PR 同時起動**: 1 セッション 1 タスク制で十分、不要
