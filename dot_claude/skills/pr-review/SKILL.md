---
name: pr-review
description: 'GitHub PR の URL または番号を渡すと、ブランチ切替・最新化、Copilot/discussion コメント取得、3-5 体のペルソナ並列レビュー、メインでの実コード裏取り、`.claude/reviews/` への所見草稿出力までを一気通貫で行う。投稿はしない（草稿のみ）。「PR レビュー」「<PR URL> を見て」「<番号> 番見て」「これマージしていい？」「ペルソナで PR 見て」等の依頼で使う。GitHub へ直接投稿したいなら公式 /code-review を使う。'
argument-hint: '<PR URL or PR番号>'
allowed-tools: Agent, Read, Glob, Grep, Bash(git:*), Bash(gh:*), Write, AskUserQuestion
---

# PR Review

GitHub PR の URL（または番号）を渡すと、ブランチ切替から所見草稿出力までを一気通貫で実施するオーケストレータ。**投稿はしない**（ローカル `.claude/reviews/` に草稿のみ）。

## 解く問題と使わない場面

「機械的な準備（ブランチ切替・コメント取得）」「観点設計（ペルソナ）」「実コード裏取り」「所見ファイル化」の 4 ステップを URL 1 つで統合し、既存の所見ファイルと同じ構造の草稿を `.claude/reviews/` に出す。ペルソナ所見を鵜呑みにした偽陽性（何度も発生し MEMORY 化済み）は Phase 4 の裏取りで落とす。

**使わない**: インラインコメントを直接投稿したい（公式 `/code-review ultra <PR#>`）/ 作業ツリーの diff をレビューしたい（公式 `/code-review`）/ 軽い疑問だけ（差分 1 ファイル数十行・タイポ確認）。

## 公式 `/code-review` との棲み分け

| 項目 | 公式 `/code-review ultra <PR#>` | `/pr-review`（本スキル） |
|---|---|---|
| 出力先 | GitHub inline コメント投稿 | ローカル `.claude/reviews/` に草稿 |
| レビュー手法 | LLM 自動 + confidence scoring（80 閾値） | 3-5 ペルソナ並列 + メイン裏取り |
| 運用ルール | 公式デフォルト | ユーザー MEMORY 系を冒頭明示遵守 |
| `--fix` モード | あり | なし（読取専用） |
| 実行場所 | クラウド | ローカル Agent 並列 |
| 判定の粒度 | confidence 0-100 → 80 未満切り捨て | CONFIRMED / PLAUSIBLE / REFUTED + severity 4 段（LOW も残す） |

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
6. **base の移動とコンフリクトの確認**（レビュー中に base が進むことがある。PR #810 のレビューで `release` がセッション中に `67023e53` → `557dbaa5` へ進んだ実例あり）:
   - `git rev-parse origin/<base>` と `MB=$(git merge-base origin/<base> HEAD)` を控え、**所見ファイル冒頭に merge-base を記録する**
   - Phase 1-4 で取った `mergeable` が `CONFLICTING` なら衝突ファイルを特定する:
     `comm -12 <(git diff --name-only $MB..HEAD | sort) <(git diff --name-only $MB..origin/<base> | sort)`
   - 各衝突ファイルについて `git diff $MB..origin/<base> -- <path>` を読み、**base 側が何を足したか**と、そこで追加された `it(...)` のタイトルを控える（Phase 4 の受け入れ条件に使う）

### Phase 2: ペルソナ案提示（★1 段承認★）

1. 4 章の指針に従い、3-5 体のペルソナ案を生成する。**うち 1-2 体は常設の角度ペルソナ**（4 章「常設の角度ペルソナ」）を体数枠の**内数**で充てる — 3 体なら角度 1 + ドメイン 2、4-5 体なら角度 2 + ドメイン残り
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
   - **アウトプット形式**: 気づいた指摘は **重要度順に全件列挙**（「重大なものだけ」「保守的に」のような件数を絞る指示は出さない。絞りは Phase 4 の裏取り 1 パスに集約する）+ 「最も効きそうな指摘トップ 3」を明示。**各指摘は `場所 / 何が起きる / 再現手順 / 根拠` の 4 項目に固定させる**（散文で書かせない。字数でなく項目数で縛る）。「根拠」＝ 逐語引用 + 到達経路は Phase 4 の裏取りの起点なので削らせない。削らせるのは経緯・背景説明・一般論。**指摘の件数は絞らせない**
   - **再現手順の層を判定させる**: `~/.claude/skills/shared/review-output-style.md` のルール 3（①画面のみ / ②DevTools 必須 / ③複数セッション / 再現不可）を prompt に貼り、指摘ごとに層を書かせる。①なら手順を番号付きで書かせる。ペルソナ側で層を判定させておくと Phase 5 で書き直す手間が消える
   - **読取専用の指示**
   - セキュリティ観点のペルソナを立てる回は、`~/.claude/skills/shared/security-review-exclusions.md` の 2 ブロックを**逐語で貼る**（要約しない）。DoS / rust のメモリ安全 / React の XSS / クライアント側の認可欠如 といった定番の偽陽性が prompt 段階で消える
3. `Agent` ツールを**同一 assistant メッセージ内**で N 回並列起動（subagent_type=`general-purpose`）
4. 各 Agent は独立に Read / Grep / Glob で実コード探索しつつ所見を返す
5. **無応答ペルソナのフォールバック**: idle 通知だけ返して所見を送ってこない体がある（`SendMessage` で 2 回催促しても返らないことがある）。その場合は**待ち続けず、そのペルソナの観点をメイン側で直接検証して Phase 4 へ進む**。所見ファイルの「メモ」に「○○ 観点はペルソナ無応答のためメインで代替検証」と明記し、代替検証で実際に見た内容（テストの `it` 全件確認 等）も書く

### Phase 4: 裏取り・統合

**ここが本スキルの肝**。ペルソナ所見を鵜呑みにせず、メインエージェントで実コードを裏取りして severity 確定する。

> **設計意図（削らないこと）**: これは「自分の作業をもう一度検証する」過剰検証ではなく、**他エージェントの主張の一次確認**である。ペルソナは前提を誤認したまま収束しうる（PR #19 実例、memory `[[feedback_delegate-facts-verbatim]]`）ため、finder 側で絞らず全件出させたぶんの偽陽性はここで落とす。「自己検証の指示は削る」という一般則の適用対象外。

1. **MEMORY 運用ルール明示参照**（5 章で詳述）
1.5. **CONFLICTING の場合はマージ解決の受け入れ条件を作る**（Phase 1-6 で控えた情報を使う）。コードの欠陥とは別枠の指摘として出す:
   - base 側が衝突ファイルへ足した変更のうち、**衝突解決で落としても型検査と当該 PR のテストが通ってしまうもの**（optional フィールド・分割代入の省略・スプレッド）を特定する。素通りするなら severity を上げる
   - 「解決の受け入れ条件 = base 側が追加したテストの通過」として、テスト名を**逐語で**所見に列挙する（author がそのまま使える形にする）
   - 詳細と実例は memory `[[feedback_pr_review_conflicting_merge]]`
2. 各所見について以下を実施:
   - 指摘対象ファイル・行を **Read** で確認
   - 関連挙動を **Grep** で他所参照含め確認
   - 差分前の挙動と比較（必要なら `git show origin/<base>:<path>`）
   - Copilot の既出指摘と突合（重複は統合、Copilot だけ拾った観点は author 対応済みかチェック）
2.5. **データの不変条件に依存する所見は、severity 確定前にユーザーへ 1 問投げる**。「その形のデータが実在するか」はコードからは決められず、DB を引ける保証も無い（ローカル DB が無い / 共有環境への SELECT が権限で止まる、はどちらも起こる）。**コード読解を尽くす前に聞く**ほうが速い。聞き方は「〜というデータは実在しますか？」の 1 問で、回答が「入らない」なら即降格、「ある」なら再現手順にその値を書ける。所見には**前提の出所**（ユーザー確認なのか実データのクエリなのか）を必ず明記する — 後から前提が変わったときに、どの指摘が復活するかを追えるようにするため。2026-08-21 の PR #815 で、HIGH 1 件が「マスタに細別まで枝が伸びていないデータは入らない」の一言で LOW へ降格した（DB は引けなかった）。

2.7. **各所見に 3 値の verdict を付ける（severity 確定の前段）**。公式 `/code-review` の verify フェーズから取り込んだ判定で、**REFUTED 側に立証責任を課す**のが目的:

   - **CONFIRMED**: 発火する入力・状態と、その結果どう間違うかを名指しできる
   - **PLAUSIBLE**: 機構は実在するがトリガが不確実（タイミング・環境・データ依存）
   - **REFUTED**: **コードから構成できるときのみ**。① 事実誤認（該当行を引用）② 型・定数・不変条件で不可能（それを提示）③ この diff 内で既に処理済み（ガード行を引用）④ 観測可能な影響のない純スタイル

   **既定は PLAUSIBLE**。「speculative だから」「ランタイム状態に依存するから」を REFUTED の理由にしてはならない。並行性レース / エラーハンドラ・コールドキャッシュ・欠落オプショナルのような稀だが到達可能なパス / falsy-zero / 境界の off-by-one / リトライ嵐・部分失敗 は**現実的な状態**として扱う。ここを緩めると、5 章の抑制ルールと合わさって実バグまで消える。

   CONFIRMED / PLAUSIBLE を残して severity へ進み、REFUTED は撤回記録へ回す（Phase 5 で所見ファイルに残す）。

3. severity 確定:
   - **CRITICAL**: セキュリティ・データ損失・本番障害
   - **HIGH**: 機能不全・パフォーマンス重大・設計大問題
   - **MIDDLE**: 保守性・潜在バグ・ベストプラクティス違反・doc 欠如
   - **LOW**: スタイル・軽微改善・推奨事項
   - **【MUST】1 つの所見に複数の症状がぶら下がるときは、「確実に起きる部分」と「条件つきの部分」を分けてから severity を付ける**。原因が 1 箇所でも、症状ごとに発生頻度と害の大きさが違う。分けずに束ねると、100% 起きる軽微な症状に引きずって過大評価するか、低頻度の重い症状を見落とすかのどちらかになる。所見には**症状 × 頻度 × 害 × 再現の層**（3 層分類は MEMORY [[feedback_pr_review_repro_tiers]]）の表を置き、そのうえで「実害ベースならこの severity」と書く。既存レビュアーが別の severity を付けているなら、揃えるか否かを理由付きで明示する。2026-08-21 の PR #815 の HIGH-1 は、視覚症状が 100%・機能症状は PUT 失敗時のみで、分けて初めて「実害ベースなら MIDDLE」と言えた（修正が 1 行なので HIGH のまま据え置いた）。
4. 偽陽性・降格判断:
   - 落とす典型は `~/.claude/skills/shared/review-false-positives.md`（`multi-persona-review` Step 3.5 と共通の SSOT）を参照する。**このリストを Phase 3 の finder prompt に入れてはならない** — 絞りは本フェーズ 1 パスに集約する既存設計を維持する
   - 裏取りで前提が崩れた所見は**撤回**（所見ファイルに「裏取りで撤回」と verdict: REFUTED を記録）
   - 実害の範囲が想定より狭いと確認できた所見は **HIGH→MIDDLE / MIDDLE→LOW** に降格（verdict は PLAUSIBLE のまま残る）
   - MEMORY 系の除外ルール（5 章）に該当する所見は撤回 or LOW。ただし**抑制ルールの適用にも 2.7 の REFUTED と同じ立証責任がかかる**

### Phase 4.5: ギャップ掃討（Agent 1 体）

Phase 3 の並列は「各ペルソナが自分の観点で見つけたもの」で打ち止めになり、**収束後の穴**が残る。公式 `/code-review` の xhigh/max だけが持つ sweep フェーズを 1 体だけ取り込む。

1. Phase 4 で確定したリスト（ファイル:行 + 一行要約）を渡し、**そこに無い欠陥だけ**を探す fresh reviewer として `Agent` を 1 体起動する
2. prompt に必ず入れる制約:
   - 既にリストにあるものの再確認・再導出は**しない**（仕事は穴埋めのみ）
   - 新規候補は最大 8 件。**無ければ空で返す — 水増ししない**
   - 狙い目（公式の逐語）: 移動・抽出でガードやアンカーが落ちたコード / 二軍の footgun（デフォルト引数が 1 回だけ評価される、ハッシュの非決定性、ロックスコープの縮小、副作用のある述語メソッド）/ テストの setup・teardown 非対称 / config デフォルトの反転
3. 返ってきた候補は **Phase 4 の 2 → 2.7 → 3 を同じ手順で通す**（裏取り → verdict → severity）。掃討結果を無検証で所見に載せない
4. 差分 < 100 行の機械的変更ではスキップしてよい。スキップした場合もその旨を Phase 5 の「メモ」に 1 行残す

### Phase 5: 所見ファイル出力

1. ファイル名: `.claude/reviews/pr-{NNN}-{branch-key-snippet}-{YYYY-MM-DD}.md`
   - `{branch-key-snippet}` = ブランチ名の最後のセグメント（`pr/sh-watanabe/feat_photoPlaceListDialog` → `photoPlaceListDialog`）
2. **書く前に `~/.claude/skills/shared/review-output-style.md` を Read する**（`multi-persona-review` Step 5 と共通の出力規約 SSOT）。所見ファイルは**初見のジュニアエンジニアが読み通せる密度**にするのが要件で、4 つのルール — ①1 指摘 4 項目・6 行以内 ②専門用語は初出で 1 行言い換え ③再現手順は層を判定して必ず書く ④削った詳細は「聞ける項目」へ見出しだけ送る — をすべて適用する。

3. 次のテンプレで **Write**:

```markdown
# PR #{NNN} レビュー所見

- 対象 / タイトル / author / base（+ merge-base）/ 規模 / 状態 / レビュー日

## 結論

<3 行以内。1 行目でブロッカーの有無を言い切る。件数は「CRITICAL0 / HIGH0 / MIDDLE9 / LOW7」のように 1 行>

## 直すなら効く順

1. **<PREFIX-N>** <1 行>
2. **<PREFIX-N>** <1 行>
3. **<PREFIX-N>** <1 行>

## 指摘一覧

| # | 重要度 | 場所 | 何が起きる | 再現 |
|---|---|---|---|---|
| 1 | MIDDLE | `path/to/file.tsx:303` | <1 行> | ①画面のみ |
| 2 | LOW | `eslint.config.mjs:35` | <1 行> | 再現しない |

## 指摘の詳細

### MIDDLE-1: <30 字以内で問題を言い切る>
- **verdict**: CONFIRMED — <1 行>
- **場所**: `path/to/file.tsx:303`
- **何が起きる**: <1 行>
- **再現手順**: <層の判定 + ①なら番号付き手順>
- **直し方**: <1 行>

（以降同じ形で全件。CRITICAL → HIGH → MIDDLE → LOW の順）

## 検証

<実行したコマンドと結果だけを表で。考察は書かない>

## 詳細を聞けば出せる項目

- <見出しだけ 1 行>

## Copilot の評価

<1〜2 行>

## 良い点

<箇条書き 3〜5 件・各 1 行>

## メモ

<投稿しない旨・Phase 4.5 掃討の結果・ペルソナの応答状況・申し送り。各 1 行>
```

3.5. **構造の要点**（旧テンプレからの変更点）:

- **`## スコープ` は廃止**。必要な情報はメタ行と結論に入る
- **`## 指摘一覧` の表を必ず置く**。読み手はまずここだけ見て、気になる行の詳細へ飛べる
- **`verdict` 行は見出し直下に維持**（CONFIRMED / PLAUSIBLE）。ただし根拠は 1 行に収める
- **REFUTED は本文に書かない**。「詳細を聞けば出せる項目」へ `REFUTED N 件それぞれの撤回理由` の 1 行で送る。ただし**前提が変われば復活するもの**は、復活条件だけ 1 行を指摘一覧の下に残す（例: 「`X` を購読するコンポーネントが増えたら MIDDLE-6 が顕在化する」）
- **`## メモ`** には `Phase 4.5 掃討: 新規 N 件`（またはスキップ理由）を 1 行記録する
- **機構の解説・ルール実装の引用・経緯・他案の比較は所見に書かない**。すべて「聞ける項目」へ見出しだけ送る。ただし**その回のレビューの結論を左右した事実**（実行して分かったこと）は「検証」節に 1 行で残す

4. ファイルパスを会話で提示する。**会話側の要約も所見ファイルと同じルールで書く**（結論 3 行 → 効く順 3 件 → 「詳細を聞けば出せる項目」の案内 1 行）。所見ファイルより会話が長くなるのは本末転倒
5. **context.md / tasks.md は触らない**（ユーザーが /context-save で別途管理）。ただし投稿要否判断が残る CRITICAL / HIGH 所見がある場合は、次セッションで拾えるよう**起票を提案**する（本スキル自身は書かない。起票先はそのリポジトリの作業キュー `.claude/tasks.md` ＝ `/context-save` の担当。文例: `PR #{NNN} (<短題>) <PREFIX><件数>の投稿要否判断 (所見 <ファイル名>)`）
6. **投稿可否は聞かない**（必要なら別途「投稿用整形」依頼可）
7. **元ブランチへの復帰はしない**（checkout のみで残す）

## ペルソナ自動生成の指針

LLM 裁量で生成。既定セットは持たない（PR 文脈で具体化する方が効く）。ただし後述の**常設の角度ペルソナ**だけは例外で、PR 文脈によらず枠を確保する。

### 常設の角度ペルソナ（体数枠の内数で 1-2 体）

ドメイン専門ペルソナ（React 状態管理 / EF Core など）は**追加された行**に目が寄り、**削除行**と**呼び出し元**が誰の担当でもなくなる。公式 `/code-review` が専門領域でなく直交する「角度」で finder を割っているのはこのため。体数は増やさず、枠の内数を割り当てる。

**角度 A「差分構造」**（3 体以上なら必ず入れる）。着眼点はそのまま番号付き質問として渡す:

1. diff が **DELETE / 置換した全行**について、それが守っていた不変条件・挙動を名指しし、新コードのどこで再確立されているか探す。見つからなければ候補（削除されたガード / 落ちたエラーパス / 狭まった検証 / 実ケースを覆っていた削除テスト）
2. 変更された関数の**呼び出し元**を Grep し、新しい事前条件・戻り値形状の変更・新例外・順序依存が call site を壊さないか確認する。callee 側も見る（同 PR の並行変更で呼び出しが安全でなくなっていないか）
3. 各 hunk の**囲む関数全体**を Read する。触られた関数の未変更行にあるバグも対象（その PR が再露出させた / 直しそこねた、と言える）
4. 指摘には必ず `ファイルパス:行番号` と逐語引用を添える

**角度 B「規約準拠 + altitude」**（4-5 体のとき追加）:

1. ユーザー `~/.claude/CLAUDE.md`、リポジトリルート、**変更ファイルの祖先ディレクトリ**の `CLAUDE.md` / `AGENTS.md` を読む（あるディレクトリの CLAUDE.md はそこ以下のファイルにのみ効く）
2. **ルール原文と違反行の両方を逐語引用できるときだけ**指摘する。スタイル嗜好・「文書の精神」からの推論は禁止。該当なしなら「なし」と返す
3. altitude: 変更が正しい深さで実装されているか。共有インフラの上に特例を重ねているのは修正が浅いサイン。下層の仕組みを一般化する案があれば出す
4. 指摘には CLAUDE.md のパスとルール原文を含める（所見ファイルでそのまま引用できる形にする）

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

体数は**独立した観点の数**で決める。上表は規模に対する**上限の目安**であって既定値ではなく、観点が 3 つに割れないなら 3 体未満でよい（1 体で足りるなら 1 体）。

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

**ただし抑制ルールの適用にも Phase 4-2.7 の REFUTED と同じ立証責任がかかる**。これらは「speculation を疑う」ためのルールであって「speculation に見えたら消す」ためのルールではない。例えば防御コード speculation を落とすなら、**データモデルの不変条件で守られていることをコードで示す**（型定義・制約・ガード行の引用）。示せないなら PLAUSIBLE のまま severity を下げるにとどめる。この歯止めが無いと、並行性レースや稀パスの実バグまで抑制ルールで消える。

## よくある失敗と回避策

Phase 本文の MUST を再掲する行は置かない。本文に書けない「なぜそうするか」だけ残す:

| 失敗 | 回避策 |
|---|---|
| ペルソナ案でユーザー承認を取らず即実行 | Phase 2 の AskUserQuestion は省略不可。承認の手間 << ピント外れペルソナで時間溶かすリスク |
| PR の変更内容を当方の言葉で略記して「確定事実」に書く | 確定事実（特に PR 本文の主張）は原文表現を保つ。略記するとペルソナがそれを PR の主張と誤認し「本文と差分が不整合」型の偽陽性を生む（PR #19 実例、memory `[[feedback_delegate-facts-verbatim]]`） |
| 大型 PR（> 2000 行）で 5 体全部に全ファイル読ませる | 各ペルソナの「担当ファイル群」を明示して責任範囲を分割（並列効率と裏取り精度の両立） |

## 関連スキル / 参考

- `~/.claude/skills/multi-persona-review/SKILL.md`: 並列ペルソナレビューのプロセス本体。本スキルは Phase 3 でこれを Read して参照知識として再利用する
- `~/.claude/docs/specs/2026-06-23-pr-review-design.md`: 本スキルの設計仕様（背景・判断ログ）
- 公式 `/code-review` plugin（`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/code-review/`）: PR 差分専用の自動レビュー。**投稿前提**ならこちらを使う。本スキルとは Phase 5 の出力形態で棲み分け
- `~/.claude/skills/shared/review-false-positives.md`: 偽陽性カタログの SSOT。Phase 4 で参照（`multi-persona-review` Step 3.5 と共通）
- `~/.claude/skills/shared/review-output-style.md`: **所見の書き方の SSOT**。Phase 5 の冒頭で Read する（`multi-persona-review` Step 5 と共通）。1 指摘 4 項目 / 用語の言い換え / 再現手順の層判定 / 「聞ける項目」への退避
- `~/.claude/skills/shared/security-review-exclusions.md`: 公式 `/security-review` の除外規定を逐語保持。security ペルソナの prompt に貼る
- `~/.claude/projects/<project>/memory/MEMORY.md`: PR レビュー系 feedback memory の索引（5 章で参照）
