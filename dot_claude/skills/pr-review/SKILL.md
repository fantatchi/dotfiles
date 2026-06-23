---
name: pr-review
description: GitHub PR の URL または番号を渡すと、ブランチ切替・最新化、Copilot/discussion コメント取得、3-5 体のペルソナ並列レビュー、メインでの実コード裏取り、ローカル `.claude/reviews/` への所見草稿出力までを一気通貫で実施するオーケストレータスキル。投稿はしない（草稿のみ）。「PR レビュー」「pr/<番号> をレビュー」「<PR URL> を見て」「PR の差分どう」「<番号> 番見て」「これマージしていい？」「PR の感想」「ペルソナで PR 見て」等の依頼で発動。公式 `/code-review ultra <PR#>` も PR 自動レビュー機能を持つが、本スキルは (a) インライン投稿せず `.claude/reviews/` に草稿のみ出力 (b) ペルソナ並列で観点分割 (c) ユーザーの MEMORY 運用ルール（SR 系除外・useMemo speculation 抑制・防御コード speculation 抑制等）を冒頭明示遵守 の点で異なる。投稿前提なら公式、ローカル草稿・ペルソナ・運用ルール反映なら本スキル。
argument-hint: <PR URL or PR番号>
allowed-tools: Agent, Read, Glob, Grep, Bash(git:*), Bash(gh:*), Write, AskUserQuestion
---

# PR Review

GitHub PR の URL（または番号）を渡すと、ブランチ切替から所見草稿出力までを一気通貫で実施するオーケストレータ。**投稿はしない**（ローカル `.claude/reviews/` に草稿のみ）。

## このスキルが解く問題

PR レビューには本来「機械的な準備（ブランチ切替・コメント取得）」「観点設計（ペルソナ）」「実コード裏取り」「所見ファイル化」の 4 ステップがあるが、毎回手作業すると以下の問題が出る:

- ブランチ切替・コメント取得・既存レビュー突合の手順が**毎回同じなのに毎回手作業**で時間を溶かす
- 観点を 1 人で出すと**専門領域偏り**で死角が残る（バックエンド人間が UI 軽視 etc.）
- ペルソナが指摘したことを**鵜呑みにすると偽陽性が混じる**（過去に何度も発生して MEMORY 化した経緯あり）
- 所見の構造が**回ごとにブレる**と過去資産との突合が効かない

本スキルは「URL 渡すだけ」で 4 ステップを統合し、過去 7 件と同じ品質・構造の所見草稿を `.claude/reviews/` に出力する。投稿は別途ユーザー判断。

## 使うべき時 / 使うべきでない時

**使う**:
- GitHub PR をローカルで確認したい
- ペルソナで観点を分解したい
- 草稿は欲しいが投稿は自分で判断したい
- 過去 7 件と同じ粒度の所見ファイルを残したい

**使わない**:
- インラインコメントを直接投稿したい（→ 公式 `/code-review ultra <PR#>` を使う）
- 現在の作業ツリーの diff をレビューしたい（→ 公式 `/code-review` を使う）
- 軽い疑問だけ（差分 1 ファイル数十行・タイポ確認 etc.）

## 公式 `/code-review` との棲み分け

| 項目 | 公式 `/code-review ultra <PR#>` | `/pr-review`（本スキル） |
|---|---|---|
| 出力先 | GitHub inline コメント投稿 | ローカル `.claude/reviews/` に草稿 |
| レビュー手法 | LLM 自動 + confidence scoring（80 閾値） | 3-5 ペルソナ並列 + メイン裏取り |
| 運用ルール | 公式デフォルト | ユーザー MEMORY 系を冒頭明示遵守 |
| `--fix` モード | あり | なし（読取専用） |
| 実行場所 | クラウド | ローカル Agent 並列 |

両方とも「PR レビュー」がトリガーになり得るが、**投稿前提**なら公式、**ローカル草稿・ペルソナ・運用ルール反映**なら本スキル。

## 実行手順

### Phase 1: 取得

1. **未コミット変更チェック**: `git status --porcelain` で**追跡対象の modified / staged**があれば中断。「未コミット変更があります。コミット or stash 後に再実行してください」とユーザーに依頼。submodule 由来の untracked（`ks-react-components/` 等）は無視する（cloud-cmp 系の常態）
2. **引数パース**:
   - `https://github.com/<owner>/<repo>/pull/<NNN>` → そのまま使う
   - 番号のみ（`462`）→ `gh repo view --json nameWithOwner` で origin remote から repo 推定
   - `<owner>/<repo>#<NNN>` → 分解して使う
3. **ブランチ切替・最新化**:
   - `gh pr view <NNN> --json headRefName,baseRefName` で head/base 取得
   - `git fetch origin <head> <base>` 
   - 現ブランチ ≠ head なら `git checkout <head>`
   - `git pull --ff-only origin <head>`（失敗時は「ff-only マージ不可。force-push 由来の可能性。ユーザー対処を待ちます」で中断）
4. **PR メタ + コメント取得**:
   - `gh pr view <NNN> --json number,title,author,headRefName,baseRefName,state,mergeable,mergeStateStatus,additions,deletions,changedFiles,body,reviews,url`
   - `gh api repos/<owner>/<repo>/pulls/<NNN>/comments --paginate`（inline コメント + Copilot）
   - `gh api repos/<owner>/<repo>/issues/<NNN>/comments --paginate`（discussion）
5. **規模把握**: `git diff --stat origin/<base>...HEAD` でファイル種別・行数を把握

### Phase 2: ペルソナ案提示（★1 段承認★）

1. 4 章の指針に従い、3-5 体のペルソナ案を生成
2. 各ペルソナについて以下を提示:
   - 専門領域（例: 「React 状態管理 / Jotai + TanStack Query 規約」）
   - 着眼点（4-6 個の番号付き質問）
   - 担当ファイル群（責任範囲）
3. **AskUserQuestion** で承認を求める:
   - 選択肢: 「このまま実行」「修正して再提示」「キャンセル」
   - 修正指示があれば反映してもう一度提示
4. 承認されたら Phase 3 へ

### Phase 3: 並列レビュー

1. `~/.claude/skills/multi-persona-review/SKILL.md` を **Read** してプロセスを参照知識として取り込む（特に Step 2「共通プロンプトのテンプレート設計」と Step 3「並列起動」）
2. 各ペルソナの prompt を作る:
   - ペルソナ定義（「あなたは XX エンジニア」）
   - **PR メタ + 確定事実**（タイトル / author / base / 規模 / 既存レビュー）
   - **読むべきリポジトリ / ファイル / コミット**（Phase 1 で取得した diff stat）
   - **4-6 個の番号付き質問**（ペルソナ固有の専門知識を引き出す）
   - **アウトプット形式**: 500-800 字 + 「最も効きそうな指摘トップ 3」
   - **読取専用の指示**
3. `Agent` ツールを**同一 assistant メッセージ内**で N 回並列起動（subagent_type=`general-purpose`）
4. 各 Agent は独立に Read / Grep / Glob で実コード探索しつつ所見を返す

### Phase 4: 裏取り・統合

**ここが本スキルの肝**。ペルソナ所見を鵜呑みにせず、メインエージェントで実コードを裏取りして severity 確定する。

1. **MEMORY 運用ルール明示参照**（5 章で詳述）
2. 各所見について以下を実施:
   - 指摘対象ファイル・行を **Read** で確認
   - 関連挙動を **Grep** で他所参照含め確認
   - 差分前の挙動と比較（必要なら `git show origin/<base>:<path>`）
   - Copilot の既出指摘と突合（重複は統合、Copilot だけ拾った観点は author 対応済みかチェック）
3. severity 確定:
   - **CRITICAL**: セキュリティ・データ損失・本番障害
   - **HIGH**: 機能不全・パフォーマンス重大・設計大問題
   - **MIDDLE**: 保守性・潜在バグ・ベストプラクティス違反・doc 欠如
   - **LOW**: スタイル・軽微改善・推奨事項
4. 偽陽性・降格判断:
   - 裏取りで前提が崩れた所見は**撤回**（所見ファイルに「裏取りで撤回」と記録）
   - speculation のみで実害なしは **HIGH→MIDDLE / MIDDLE→LOW** に降格
   - MEMORY 系の除外ルール（5 章）に該当する所見は撤回 or LOW

### Phase 5: 所見ファイル出力

1. ファイル名: `.claude/reviews/pr-{NNN}-{branch-key-snippet}-{YYYY-MM-DD}.md`
   - `{branch-key-snippet}` = ブランチ名の最後のセグメント（`pr/sh-watanabe/feat_photoPlaceListDialog` → `photoPlaceListDialog`）
2. 既存テンプレ準拠で **Write**:

```markdown
# PR #{NNN} レビュー所見

- 対象 / タイトル / author / base / 規模 / 状態 / レビュー日

## スコープ
## 結論（CRITICAL / HIGH 件数を冒頭明示。なければ「ブロッカーなし」）
## 検証（pass テスト・grep 結果・確認した実装位置）
## 確定指摘
### CRITICAL: ...
### HIGH: ...
### MIDDLE: ...
### LOW: ...
## Copilot N 件の評価（妥当・対応済み・見送り判断 etc.）
## 良い点
## メモ（投稿しない旨・残課題・申し送り）
```

3. ファイルパスを会話で提示
4. **context.md / tasks.md は触らない**（ユーザーが /context-save / /gtd-* で別途管理）
5. **投稿可否は聞かない**（過去 7 件と同じ運用、必要なら別途「投稿用整形」依頼可）
6. **元ブランチへの復帰はしない**（checkout のみで残す）

## ペルソナ自動生成の指針

LLM 裁量で生成。既定セットは持たない（PR 文脈で具体化する方が効く）。

### ファイル種別 → 専門領域マッピング

| 差分ファイル種別 | 専門領域候補 |
|---|---|
| `*.tsx` / `*.ts`（React） | React 状態管理 / 型安全 / UX・バリデーション |
| `*.cs`（ASP.NET Core） | VSA Endpoint 設計 / EF Core クエリ / セキュリティ / DI |
| `*.test.ts` / `*.spec.ts` 主体 | テスト設計・カバレッジ・実効性 |
| `*.scss` / `*.css` | CSS 回帰・layer 境界・デザイントークン整合 |
| `*.yml`（CI/Actions） | CI/CD 設計・secrets 取り回し・キャッシュ |
| `package.json` / `package-lock.json` | 依存サプライチェーン・peer dep・脆弱性 |
| `*.sql` / `migrations/` | スキーマ進化・データ移行・破壊的変更 |
| Route Handler (`app/api/`) | BFF 境界・認可・proxy 経路 |

### PR 性質マーカー

タイトル・本文から導出:

- `fix(` — バグ修正中心 → ロジック整合・回帰観点強化
- `feat(` — 新機能 → UX・データ整合・テストカバレッジ
- `refactor(` — 内部構造変更 → **挙動保存検証**を最重視
- `chore(deps)` — 依存更新 → 破壊的変更・peer dep・サプライチェーン
- `perf(` — パフォーマンス → ベンチ・回帰
- `style(` / フォーマット — レビュー価値低、3 体最小 or 短評提案

### PR 規模による体数調整

| 規模（差分行数） | 既定体数 |
|---|---|
| < 100（機械的変更のみ） | 短評提案（ペルソナなしも検討） |
| 100 - 300 | 3 体 |
| 300 - 1000 | 4 体 |
| > 1000 | 5 体 |

### multi-persona-review の典型例を PR 文脈で具体化

| 典型 | PR 文脈での具体化例 |
|---|---|
| シニア開発 | 「React 状態管理 / Jotai + TanStack Query 規約」 |
| セキュリティ | 「Next.js Route Handler の認可境界 / Auth.js v5 JWT 経路」 |
| テスト設計 | 「Vitest + MSW / カバレッジ実効性 / エッジ網羅」 |
| アクセシビリティ | **省略可**（MEMORY `feedback_pr_review_screen_reader` 準拠） |

## MEMORY 運用ルール遵守（Phase 4 冒頭で明示参照）

裏取り時に**毎回踏み外しやすい**ので、Phase 4 の冒頭で以下を明示参照する。MEMORY.md 経由で常時注入されているが、レビュー文脈では特に意識しないと忘れがち:

| MEMORY エントリ | 適用ルール |
|---|---|
| `feedback_pr_review_screen_reader` | SR 系指摘は省略（aria-label / role / aria-live 等は出さない） |
| `feedback_useMemo_no_speculative` | 計測なし useMemo を HIGH に上げない |
| `feedback_pr_review_speculative_defense` | 発生しないシナリオの防御コードを HIGH に上げない、データモデル不変条件で守られているなら撤回 |
| `feedback_pr_review_mock_temporary` | BE 未実装 mock の構造指摘は見送る |
| `feedback_pr_review_verify_before_severity` | ペルソナ指摘は**前提裏取りしてから** severity 確定（収束=高信頼でも前提誤認は共有されうる） |
| `feedback_commit_one_per_sonarqube_finding` | 静的解析対応の粒度（1 指摘 1 コミット）の言及 |
| `feedback_quality_gate_wording` | Quality Gate を「緑化」と言わない（「通す/パスさせる」） |
| `feedback_force_push_repo_workflow` | 別 PR のファイルはその PR ブランチへ直接コミット |

これらに該当する所見は **Phase 4 で撤回・降格** し、所見ファイルに「裏取りで降格 / 撤回」を明記する（過去のレビュアー自身の判断軌跡を残す）。

## よくある失敗と回避策

| 失敗 | 回避策 |
|---|---|
| ペルソナ案でユーザー承認を取らず即実行 | Phase 2 の AskUserQuestion は省略不可。承認の手間 << ピント外れペルソナで時間溶かすリスク |
| ペルソナ所見をそのまま所見ファイルに転記 | Phase 4 の裏取りを省略しない。実コード Read で前提を必ず確認する |
| MEMORY ルール（SR・speculation 防御）を知らずに HIGH 量産 | Phase 4 冒頭で 5 章の表を明示参照する |
| Copilot 既出指摘の重複転記 | gh api でコメント取得済なので Phase 4 で必ず突合する |
| 投稿してしまう | このスキルは草稿のみ。投稿は別途ユーザー判断（gh pr review 系は呼ばない） |
| 元ブランチに戻してしまう | Q2 決定（checkout のみ）に従い復帰しない。ユーザーが次に何をするかは自由 |
| `.claude/reviews/` 以外に出力 | 既存 7 件と一貫させるため出力先固定。context.md からのリンクを壊さない |
| 大型 PR（> 2000 行）で 5 体全部に全ファイル読ませる | 各ペルソナの「担当ファイル群」を明示して責任範囲を分割（並列効率と裏取り精度の両立） |

## 関連スキル / 参考

- `~/.claude/skills/multi-persona-review/SKILL.md`: 並列ペルソナレビューのプロセス本体。本スキルは Phase 3 でこれを Read して参照知識として再利用する
- `~/.claude/docs/specs/2026-06-23-pr-review-design.md`: 本スキルの設計仕様（背景・判断ログ）
- 公式 `/code-review` plugin（`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/code-review/`）: PR 差分専用の自動レビュー。**投稿前提**ならこちらを使う。本スキルとは Phase 5 の出力形態で棲み分け
- `~/.claude/projects/<project>/memory/MEMORY.md`: PR レビュー系 feedback memory の索引（5 章で参照）
