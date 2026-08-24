---
name: pr-review
description: GitHub PR の URL、owner/repo#番号、または番号を受け取り、作業ツリーを切り替えずに差分、実装、既存レビュー、競合状態を検証し、ローカルの .claude/reviews/ に投稿前のレビュー草稿を作成する。PR レビュー、マージ可否、PR 差分の確認を依頼された場合に使う。GitHub へ投稿する依頼やローカル未コミット差分だけのレビューには使わない。
---

# PR Review

GitHub PR を再現可能な base/head SHA で検証し、根拠付きのレビュー草稿をローカルへ残す。GitHub へのコメント、レビュー送信、承認、マージ、push は行わない。

## 適用範囲と承認境界

- 対象は GitHub PR。URL、`owner/repo#123`、または現在のリポジトリに対する番号を受け付ける。
- 通常の「PR をレビューして」はルートエージェント単独で実行する。
- ユーザーが「ペルソナ」「複数観点」「サブエージェント」「委譲」「並列」を明示した場合だけ、`multi-persona-review` Skill を併用する。
- レビュー取得、`git fetch`、一時的な非破壊検証、ローカル草稿作成までを行う。認証情報は表示・記録しない。
- `gh pr review`、`gh pr comment`、`gh issue comment`、マージ、push などの外部書込みは、別途明示的に依頼されてもこの Skill 内では実行しない。草稿完成後に別作業として扱う。

現在の作業ツリーに未コミット変更があっても、対象 SHA の Git オブジェクトだけを読むため中断しない。既存変更を変更、stash、checkout、reset しない。

## 1. 対象を確定する

1. 対象階層の `AGENTS.md` と、存在するレビュー規約を読む。
2. 入力を解析する。
   - `https://github.com/<owner>/<repo>/pull/<number>`
   - `<owner>/<repo>#<number>`
   - 番号のみ。この場合は `gh repo view --json nameWithOwner` で現在のリポジトリを使う。
3. URL のリポジトリと現在のローカルリポジトリが一致することを `gh repo view` と remote で確認する。一致しない場合は、正しいローカル clone での実行を依頼して停止する。
4. `gh auth status` を安全に確認する。出力に認証情報を含めない。認証やネットワークで取得できない場合は、推測で続けずブロッカーを報告する。

対象リポジトリを clone し直したり、別リポジトリへ自動移動したりしない。

## 2. PR の証拠を取得する

GitHub API とローカル Git を使い、少なくとも次を取得する。

- PR 番号、URL、タイトル、本文、author、state、draft、base/head ブランチ。
- base/head の完全な commit SHA。
- changed files、additions、deletions、mergeable、mergeable_state。
- review、inline review comment、discussion comment。

API の PR 応答に含まれる `base.sha` と `head.sha` をレビューの固定点として記録する。PR 本文や既存コメントをペルソナへ渡す場合、重要な主張は要約せず原文を使う。要約する場合は「当方要約」と明示する。

必要な Git オブジェクトだけを取得する。worktree を変更するコマンドを使わない。

```text
git fetch --no-tags <remote> <base-branch> refs/pull/<number>/head
```

取得後、API の base/head SHA が `git cat-file -e <sha>^{commit}` で読めることを確認する。fork PR や remote 構成のため取得できない場合は、PR head の remote URL を確認し、明示的な SHA を fetch する。checkout、switch、pull はしない。

次を SHA 指定で調べる。

```text
git merge-base <base-sha> <head-sha>
git diff --find-renames --stat <base-sha>...<head-sha>
git diff --find-renames --name-status <base-sha>...<head-sha>
git diff --find-renames --check <base-sha>...<head-sha>
```

差分のファイルを作業ツリーから読まない。PR head は `git show <head-sha>:<path>`、base との比較は `git show <base-sha>:<path>`、参照検索は `git grep <pattern> <head-sha> -- <path>` を使う。

## 3. レビュー観点を設計する

差分の性質、リスク、言語、ファイル境界から観点を選ぶ。固定の職種名ではなく、失敗モードを区別できる専門性にする。

- バグ修正: 真因との対応、回帰、境界値、再現テスト。
- 新機能: データ不変条件、認可、UX、後方互換性、テスト。
- リファクタリング: 挙動保存、呼出元、エラー経路、削除漏れ。
- 依存更新: breaking change、lockfile、peer dependency、供給網。
- CI・設定: secret 境界、権限、キャッシュ、失敗時挙動。
- migration・SQL: ロールバック、既存データ、ロック、段階展開。

明示的な並列レビュー依頼がある場合は `multi-persona-review` の指示を完全に読み、基本 3 人、独立性が十分なら最大 5 人へ自己完結した担当範囲を渡す。各子エージェントには base/head SHA、対象ファイル、確定事実、既存コメント、固有の問いを渡し、編集と外部書込みを禁止する。

並列依頼がない場合は、同じ観点をルートエージェントが順に検証する。

## 4. 所見を裏取りする

発見した候補はすべてルートエージェントが head/base の実コードで裏取りする。子エージェントや既存 reviewer の主張だけで重要度を確定しない。

各候補について次を確認する。

1. PR が導入した問題か。base に既に存在する問題は今回の所見から除外する。
2. 実行経路と呼出元が存在するか。型、設定、データモデルの不変条件で到達不能なら撤回する。
3. 既存テスト、型検査、lint、CI が防ぐか。機械的に確実に検出されるだけの指摘は原則除外する。
4. 既存の inline/discussion コメントと重複するか。重複は統合し、author の対応済み変更まで確認する。
5. 事実、推論、未確認の前提を分けられるか。
6. 反証条件または最小の追加検証を示せるか。

データの実在性など、コードと提供資料だけでは重要度が大きく変わる不変条件が残る場合は、ユーザーへ短い 1 問を出して回答を待つ。質問前に、コードから確認可能な範囲は調べる。草稿には前提の出所を記録する。

1 つの原因に複数の症状がある場合、症状ごとに発生条件、頻度、害、再現方法を分けてから重要度を付ける。修正の容易さだけで重要度を上げない。

重要度はユーザー共通規約に従う。

- `CRITICAL:` セキュリティリスク、データ損失、本番障害。
- `HIGH:` 機能不全、重大な性能問題、大きな設計問題。
- `MIDDLE:` 潜在的バグ、保守性、ベストプラクティス、文書不足。
- `LOW:` 軽微な改善、スタイル、推奨事項。

各所見へ 0〜100 の確信度を付け、原則 60 未満は確定指摘に含めない。CRITICAL 候補は低確信でも、理由と追加検証を保留事項へ残してよい。

次のような推測だけで重要度を上げない。

- 計測のない `useMemo` などの性能最適化。
- データモデル上発生しない状態への防御コード。
- 一時的と明示された mock の将来構造。
- 実行経路が示せない一般論上の脆弱性。

アクセシビリティやプロジェクト固有の除外は、適用される `AGENTS.md`、仕様、レビュー方針に従う。存在しない Claude MEMORY のキーを規約として仮定しない。

## 5. 競合と base 移動を確認する

GitHub が競合を報告する場合、merge-base から head 側と base 側の両方で変更されたファイルを特定する。コード欠陥とは別に、解消時に失われ得る base 側の挙動・テスト・設定を受け入れ条件として列挙する。

草稿作成前に PR API を再取得し、base/head SHA が開始時から変わっていないか確認する。

- head SHA が変わった場合: 古い差分の所見を確定せず、新しい head を取得してレビューを更新する。
- base SHA だけが変わった場合: 新しい base を取得し、diff、競合、採用所見を再確認する。
- 再取得中にも SHA が動き続ける場合: 確認した SHA と時刻を明記し、レビューが暫定であることを報告する。

## 6. 非破壊的な検証を行う

差分に対応する既存の lint、型検査、テストを選ぶ。現在の worktree が head SHA と一致し、既存変更へ影響しない場合はそのまま実行できる。

一致しない場合、必要性が高く、依存関係を追加取得せず実行できるときだけ、`mktemp -d` 配下へ detached worktree を作って検証する。自分で作成した一時 worktree だけを後始末する。パッケージ導入、lockfile 更新、外部環境への接続、本番向け切替は行わない。

検証できない場合は、未実行のコマンドと理由を草稿へ記録する。テスト未実行を成功として扱わない。

## 7. ローカル草稿を作る

`.claude/reviews/` に次の名前で Markdown を新規作成する。

```text
pr-<number>-<branch-last-segment>-<YYYY-MM-DD>.md
```

branch 部分は安全な英数字・ハイフンへ正規化する。同名ファイルが既に存在する場合は上書きせず、SHA の短縮形または連番を加える。編集には `apply_patch` を使う。

草稿には次を含める。

```markdown
# PR #<number> レビュー所見

- URL / タイトル / author / base / head
- base SHA / head SHA / merge-base / レビュー日時
- 規模 / state / mergeability

## 結論
CRITICAL・HIGH 件数と、マージを妨げる所見の有無。

## スコープと検証
読んだ差分、実行したコマンド、未実行検証と理由。

## 確定指摘
### HIGH: <要約>
根拠、影響、再現条件、ファイル:行番号、確信度、推奨修正。

## 既存レビューコメントの評価
妥当 / 対応済み / 重複統合 / 見送りと理由。

## 良い点

## 保留事項と申し送り
```

所見は重要度順、同じ重要度では影響度順に並べる。所見がなければ「ブロッカーなし」と明記し、確認範囲と残存リスクを示す。良い点は根拠があるものだけを書く。

context、progress、tasks は変更しない。CRITICAL または HIGH の投稿判断が残る場合だけ、別途タスク化を提案する。

## 完了報告

会話では草稿ファイルへのリンク、結論、CRITICAL/HIGH 件数、検証結果、確認した base/head SHA を簡潔に示す。GitHub へ投稿していないことを明記する。レビュー後も元のブランチと作業ツリーを変更しない。
