---
name: ks-standup
description: '朝会で読み上げる業務報告を作る。前営業日（または指定日）の業務分（org ks-kentem と会社アカウント kentem-* のリポジトリ）だけを、作業ログと GitHub の実績から Issue ごとに時刻つきの出来事を並べた箇条書きにする。`/ks-standup [YYYY-MM-DD]` で明示呼び出しする（自動発火しない）。'
argument-hint: '[YYYY-MM-DD]'
disable-model-invocation: true
allowed-tools: Read, Bash(date:*), Bash(ls:*), Bash(gh:*)
---

# ks-standup — 朝会の業務報告

前営業日の業務を、朝会でそのまま読み上げられる粒度の箇条書きにして**ターミナルに出す**（ファイルには保存しない）。業務の範囲は、GitHub の org `ks-kentem` と、会社アカウント `kentem-*`（自分は `kentem-at-kato`）が持つリポジトリに関わるものだけ（`kentem-*` は会社での作業。2026-11-25 ユーザー確認。kala = `kentem-at-kato/ks-access-log-analyzer` がこれに当たる）。kabuto・yoroi・genjuu などの業務外は、作業ログがあっても出さない（名前の除外リストではなくリポジトリの持ち主で絞るので、新しい業務外プロジェクトが増えても漏れない）。

全プロジェクトを Obsidian に記録するのは `obsidian-daily` の役目で、本スキルはそれと出口が違う（口頭報告用・業務分だけ）。

## 1. 対象日を決める

- 引数 `YYYY-MM-DD` があればその日
- なければ前営業日: 今日から 1 日ずつ戻り、土日を飛ばした最初の日
- **祝日は 0 件で判定して飛ばす**: 休日出社はない（ユーザー確認 2026-11-24）ので、引数なしで決めた日が 2・3 節で業務分 0 件なら、祝日とみなして 1 つ前の平日へ戻り 2 節からやり直す（最大 5 平日まで）。祝日の暦は持たない（WSL に jpholiday 等が無く、外部 API も足さないため）。飛ばしたときは 6 節の検証レベルに「<元の日> は業務分 0 件のため祝日とみなし、<D> 分で作った」と 1 行添える。引数で日付を指定したときは飛ばさない

```bash
d=$(date -d yesterday +%F); while [ "$(date -d "$d" +%u)" -ge 6 ]; do d=$(date -d "$d -1 day" +%F); done; echo "$d"
```

以下 `<D>` を対象日（`YYYY-MM-DD`）、`<D8>` を `YYYYMMDD`、`<YM>` を `YYYYMM` とする。

## 2. 作業ログを読む

`~/ObsidianVault/20_log/<YM>/` のうち、ファイル名が `<D8>` で始まるものを全部 Read する（日をまたいだセッションは翌日付のファイル名になることがあるので、本文の `date:` が `<D>` のものも拾う）。

業務分の判定: 本文に `ks-kentem/` か `kentem-*/` のリポジトリ・PR / Issue の URL が出てくる、または frontmatter の `project` のリポジトリの持ち主が `ks-kentem` か `kentem-*` であるログだけを残す（cloud-cmp・specmaster-search-dialog・ks-access-log-analyzer など。持ち主が分からなければ、手元の clone の `git remote get-url origin` で確かめる）。判断がつかないログは報告に入れず、6 節の「要確認」に「業務分か判定できなかったログ」として名前を出す。

## 3. GitHub で状態を確かめる

アカウントは `kentem-at-kato`（private repo は他アカウントの token では 0 件で返る）。`gh api user --jq .login` が `kentem-at-kato` でなければ、各 `gh` コマンドの頭に `GH_TOKEN=$(gh auth token -u kentem-at-kato)` を付ける。`gh auth switch` は使わない（戻し忘れると、その後の push が別アカウントになる）。

search クエリの罠（先頭スラッシュを付けない、日付範囲は JST で `+` を `%2B` にする）は `~/.claude/skills/obsidian-daily/SKILL.md` の「クエリの罠」と同じ。範囲は**対象日以降すべて** `%3E%3D<D>T00:00:00%2B09:00`（`>=`。以下 `<R>`）。`updated:` は最終更新日時なので、対象日だけに絞ると、その日に手を動かしたあと翌日以降に更新された PR が漏れる（2026-11-20 分で、指摘対応した PR #1723 が 11/23 の更新で漏れた）。対象日より後の分は下の絞り込みで落とす。

`org:` と `user:` を並べると OR になる（2026-11-25 に 7 件 + 1 件 = 8 件で確認）。ほかの `kentem-*` アカウントのリポジトリはワイルドカードで検索できないので、作業ログに出てきたときだけ `user:<そのアカウント>` を足す。以下の `<owner>` はリポジトリの持ち主（`ks-kentem` / `kentem-at-kato` など）。

逐次実行する（search の rate limit が 30 req/min のため）:

```bash
gh api 'search/issues?q=org:ks-kentem+user:kentem-at-kato+author:kentem-at-kato+type:pr+updated:<R>&per_page=100' --jq '.items[] | [.number, .repository_url, .state, .title] | @tsv'
gh api 'search/issues?q=org:ks-kentem+user:kentem-at-kato+reviewed-by:kentem-at-kato+type:pr+updated:<R>&per_page=100' --jq '.items[] | [.number, .repository_url, .user.login, .state, .title] | @tsv'
gh api 'search/issues?q=org:ks-kentem+user:kentem-at-kato+involves:kentem-at-kato+type:issue+updated:<R>&per_page=100' --jq '.items[] | [.number, .repository_url, .state, .title] | @tsv'
```

- 候補には他人の更新や対象日より後の作業も混ざるので、自分の PR は「対象日（JST）に自分のコミットがある・作成した・マージした」か作業ログに出てくるものだけを残す。Issue は作業ログと突き合わせる。コミットの数え方:
  ```bash
  gh api 'repos/<owner>/<repo>/pulls/<n>/commits?per_page=100' --jq '[.[] | select(.commit.author.date >= "<D-1>T15:00:00Z" and .commit.author.date < "<D>T15:00:00Z")] | length'
  ```
- 自分の PR は `gh pr view <n> -R <owner>/<repo> --json closingIssuesReferences,state` で Issue にまとめ、Issue の state を `gh issue view` で**今の時点の値**として取る
- **レビューの正は提出日時**: ブラウザだけでしたレビューは作業ログに残らない（2026-11-16 は Approve 5 件のうち 3 件がログに無かった）。2 本目の search の候補それぞれについて、自分のレビューの `submitted_at` が対象日（JST）に入るかを確かめ、入るものだけを残す。自分の PR（スレッドへの返信もレビュー扱いで当たる）は除く
  ```bash
  gh api 'repos/<owner>/<repo>/pulls/<n>/reviews' --jq '[.[] | select(.user.login=="kentem-at-kato") | select(.submitted_at >= "<D-1>T15:00:00Z" and .submitted_at < "<D>T15:00:00Z") | .state] | join(",")'
  ```
  （`<D-1>` は対象日の前日。JST の 0 時は UTC の前日 15 時）
- 正式なレビューを出さず実機確認だけした PR は search に出ないので、作業ログを根拠に足す（状態は「実機確認まで」とし、5 節の要確認にも回す）
- レビューした PR は作成者（`author.login`）・自分のレビューの種別（APPROVED / COMMENTED / CHANGES_REQUESTED）・今の state・紐づく Issue（`closingIssuesReferences`）を取る。報告では作成者を「〇〇さん」と姓で書く（作業ログの呼び方に合わせる。ログに出てこない人はログイン名の姓の部分を使う）
- **出来事の時刻を集める**（4 節は時刻順に並べるため）。対象日（JST）に入るものだけを拾い、JST の `HH:MM` に直す:
  - 自分の PR: 作成（Draft で作ったときは `ready_for_review` の時刻）・マージ（`mergedAt`。`mergedBy` が自分のときだけ）・対象日のコミット（最後のコミットの時刻。何をしたかは作業ログから取る）。親に方針のコメントが無いときは、最初のコミットの時刻も取る（4 節の「実装を開始」）
    ```bash
    gh pr view <n> -R <owner>/<repo> --json createdAt,isDraft,mergedAt,mergedBy
    gh api 'repos/<owner>/<repo>/issues/<n>/timeline?per_page=100' --jq '[.[] | select(.event=="ready_for_review") | .created_at]'
    ```
  - 自分の Issue へのコメント（方針の共有など）: 最初に書いた時刻（`created_at`）
    ```bash
    gh api 'repos/<owner>/<repo>/issues/<n>/comments?per_page=100' --jq '.[] | select(.user.login=="kentem-at-kato") | .created_at'
    ```
  - レビュー: 上で確かめた `submitted_at`
  - 開いている自分の PR は、対象日より後に他人から付いたレビューも取る（「→ 今の状態」に使う）
  - Redmine の対応方法の記載: 作業ログに「対応方法の文面」を書いた記録があれば、そのリポジトリの `.claude/pr/redmine-responses-<D>*.md` の更新時刻を記載した時刻とする（文面は出力の直後にユーザーが Redmine へ反映している。2026-11-25 ユーザー確認）。各ファイルの `## #<Redmine 番号> … — PR #<n>` の見出しから PR を引き、PR から Issue を引く
    ```bash
    ls -l --time-style='+%F %T' <repo>/.claude/pr/redmine-responses-<D>*.md; grep -h '^## ' <repo>/.claude/pr/redmine-responses-<D>*.md
    ```

## 4. 組み立てる

出力の正本（2026-11-25 に 11/24 分でユーザーと合意した形。それまでの「完了 / 対応中 / レビュー」の見出し分けは廃止。2026-11-27 に、リポジトリの中を「開発」と「レビュー」に分ける形を足した）:

```
**11/24（火）作業報告**

**cloud-cmp**

開発
- #1272 単位の変更（差し戻し分）
  - 10:32 方針をコメント
  - 14:14 手入力の単位から一覧の単位に変えたときも規格値などを削除するよう修正（実機確認済み）
  - 14:51 PR #1753 でレビュー依頼
  - 16:03 Redmine に対応方法を記載 → 今朝、渡邊さんから PR にコメントあり（未対応）
- PR #1730 依存パッケージの更新
  - 11:05 実装を開始
  - 11:20 依存を上げてテストを修正
  - 11:40 PR を作成 → レビュー待ち
- マージと Redmine の記載のみ（すべてクローズ）
  - #1274 略図の拡張子が重複して表示される
  - #1641 破損 PNG で形式エラーと表示される（衝突を解消してマージ）

レビュー（すべて勝亦さん担当）
- 16:34 #1232 照合で未確定のまま画面を離れても確認が出ない：PR #1727 を実機確認のうえ Approve → 今朝マージ、クローズ

**ks-access-log-analyzer（kala）**

開発
- PR #32 レポートに「課題と次の一手」タブを足す
  - 13:10 実装を開始
  - 17:27 課題を AI でなくルールで出す形にして実装し、PR を作成 → 未マージ（レビュー依頼なし）
```

（#1730 は Issue の無い PR の書き方を示す例で、11/24 の実績には無い。ほかは 11/24 分の抜粋）

規則:
- **リポジトリ名を太字の見出しにし、その下に Issue を親の行（`#<Issue> <題>`）、その日の出来事を子の行（`<時刻> <出来事>`）として時刻順に並べる**。時刻は JST の `HH:MM`
- **リポジトリの中は「開発」「レビュー」の 2 つに分ける**（自分が手を動かした分とレビューだけの分を見分けるため。2026-11-27 ユーザー依頼）。「開発」が先、「レビュー」が後。中身の無い方は出さないが、片方だけでもラベルは出す
- リポジトリの見出しは正式なリポジトリ名にし、ふだんの呼び名があれば括弧で添える（`ks-access-log-analyzer（kala）`）。1 リポジトリだけの日も見出しを出す
- リポジトリは、その中の**最初の出来事の時刻順**に並べる（レビューも含める）。親の行も同じく、「開発」「レビュー」それぞれの中で、その Issue の最初の出来事の時刻順。同じ時刻なら次の出来事が早い順
- **「開発」の中で、作業した親と手続きだけの親を分ける**（手間の大小を見分けるため。2026-11-25 ユーザー合意）:
  - 作業した親: その日に、自分のコミット（release などを取り込んだマージコミット = 親が 2 つのコミットは除く）か、方針・原因調査のコメントがあるもの。上の形で時刻つきに並べる
  - 手続きだけの親: マージ・Redmine の記載・レビュー依頼しかないもの。「開発」の最後に「マージと Redmine の記載のみ」の子にまとめ、時刻を省いて `#<Issue> <題>` を 1 行ずつ並べる（並びはマージの時刻順）。全部クローズしていれば見出しに「（すべてクローズ）」と添え、開いているものがあれば行末に「→ 今の状態」を付ける。衝突の解消など、取り込みだけのコミットは括弧で添える
- 親に方針のコメントが無いときは、最初のコミットの時刻で「実装を開始」の子の行を足す（方針のコメントがあれば、それが着手の時刻を示すので足さない）
- PR は子の行の中に `PR #<n>` で書く
- **「レビュー」は、自分のレビューしかない Issue / PR を 1 件 1 行で並べる**: `<時刻> #<Issue> <題>：PR #<n> を Approve → 今の状態`（時刻は `submitted_at`、種別は Approve / コメント / 変更依頼）。担当者は行末に「（〇〇さん担当）」と添え、全件が同じ人なら「レビュー（すべて〇〇さん担当）」とラベルに寄せて各行からは外す。同じ Issue に自分のコミットや方針のコメントもあれば、その Issue は「開発」に入れ、レビューは子の行にする
- **Issue に紐づかない PR** は、Issue の代わりに `PR #<n> <PR の題>` を書く（「開発」では親の行、「レビュー」では行の頭）。Issue と同じ並びに混ぜる
- 「→ 今の状態」は、その親の最後の子の行にだけ付ける（クローズ / レビュー待ち / 指摘の未対応 / 未マージ など、今の時点の値）
- 題は Issue のタイトルを短く言い換える（「不具合修正⑯【優先度２】」のような接頭辞は落とす）
- Redmine の個別番号・検証の細部（テスト件数・変異テスト・ペルソナ名）・コミット SHA・ブランチ名は書かない
- Redmine の記載は Issue ごとに子の行として入れる（1 ファイルに複数の Issue 分を書いたときは、どれも同じ時刻になる）
- 実機確認は、本人が「済」と言ったものだけ、修正やレビューの子の行に「（実機確認済み）」「実機確認のうえ」と添える
- GitHub にも `.claude/pr/` のファイルにも時刻が残らない作業（作業ログにしか無いもの）は本文に入れず、6 節の「要確認」に回す
- 業務分が 0 件なら、引数なしのときは 1 節の祝日判定で前の平日へ戻る。引数で指定した日が 0 件なら「<D> の業務分の作業ログ・GitHub 実績は見つからなかった」とだけ返す

## 5. gh で確かめられない事項は本文に書かない

作業ログにしか根拠がない状態（実機確認の完了・口頭での合意など。Redmine の対応方法の記載は 3 節のファイル時刻で扱う）は、作業ログの時点から変わっていることがある（2026-11-17、ログでは「投稿はこれから」の Redmine が実際は投稿済みだった）。報告本文には入れず、6 節の「要確認」に回す。本人が「済」と言えば、その場で本文に足して出し直す。

## 6. 出力

報告本文をそのままコピーできるように出し、その後ろに区切りを入れて次を短く添える:

- **要確認**: 5 節で回した事項と、2 節で判定できなかったログ。1 行ずつ、本文のどこに足すかの案つき
- **検証レベル**: Issue / PR の state は gh で確認した（いつの時点か）、作業内容は作業ログから拾った、の 2 行
