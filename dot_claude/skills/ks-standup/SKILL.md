---
name: ks-standup
description: '朝会で読み上げる業務報告を作る。前営業日（または指定日）の org ks-kentem 分だけを、作業ログと GitHub の実績から「完了 / 対応中 / レビュー」の短い箇条書きにする。自分の担当分は Issue 単位、レビューは PR 単位。`/ks-standup [YYYY-MM-DD]` で明示呼び出しする（自動発火しない）。'
argument-hint: '[YYYY-MM-DD]'
disable-model-invocation: true
allowed-tools: Read, Bash(date:*), Bash(ls:*), Bash(gh:*)
---

# ks-standup — 朝会の業務報告

前営業日の業務を、朝会でそのまま読み上げられる粒度の箇条書きにして**ターミナルに出す**（ファイルには保存しない）。業務の範囲は GitHub の org `ks-kentem` に関わるものだけ。kabuto・yoroi・genjuu などの業務外は、作業ログがあっても出さない（名前の除外リストではなく org で絞るので、新しい業務外プロジェクトが増えても漏れない）。

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

業務分の判定: 本文に `ks-kentem/` のリポジトリ・PR / Issue の URL が出てくる、または frontmatter の `project` が ks-kentem のリポジトリ名（cloud-cmp・specmaster-search-dialog など）であるログだけを残す。判断がつかないログは報告に入れず、6 節の「要確認」に「業務分か判定できなかったログ」として名前を出す。

## 3. GitHub で状態を確かめる

アカウントは `kentem-at-kato`（private repo は他アカウントの token では 0 件で返る）。`gh api user --jq .login` が `kentem-at-kato` でなければ、各 `gh` コマンドの頭に `GH_TOKEN=$(gh auth token -u kentem-at-kato)` を付ける。`gh auth switch` は使わない（戻し忘れると、その後の push が別アカウントになる）。

search クエリの罠（先頭スラッシュを付けない、日付範囲は JST で `+` を `%2B` にする）は `~/.claude/skills/obsidian-daily/SKILL.md` の「クエリの罠」と同じ。範囲は**対象日以降すべて** `%3E%3D<D>T00:00:00%2B09:00`（`>=`。以下 `<R>`）。`updated:` は最終更新日時なので、対象日だけに絞ると、その日に手を動かしたあと翌日以降に更新された PR が漏れる（2026-11-20 分で、指摘対応した PR #1723 が 11/23 の更新で漏れた）。対象日より後の分は下の絞り込みで落とす。

逐次実行する（search の rate limit が 30 req/min のため）:

```bash
gh api 'search/issues?q=org:ks-kentem+author:kentem-at-kato+type:pr+updated:<R>&per_page=100' --jq '.items[] | [.number, .repository_url, .state, .title] | @tsv'
gh api 'search/issues?q=org:ks-kentem+reviewed-by:kentem-at-kato+type:pr+updated:<R>&per_page=100' --jq '.items[] | [.number, .repository_url, .user.login, .state, .title] | @tsv'
gh api 'search/issues?q=org:ks-kentem+involves:kentem-at-kato+type:issue+updated:<R>&per_page=100' --jq '.items[] | [.number, .repository_url, .state, .title] | @tsv'
```

- 候補には他人の更新や対象日より後の作業も混ざるので、自分の PR は「対象日（JST）に自分のコミットがある・作成した・マージした」か作業ログに出てくるものだけを残す。Issue は作業ログと突き合わせる。コミットの数え方:
  ```bash
  gh api 'repos/ks-kentem/<repo>/pulls/<n>/commits?per_page=100' --jq '[.[] | select(.commit.author.date >= "<D-1>T15:00:00Z" and .commit.author.date < "<D>T15:00:00Z")] | length'
  ```
- 自分の PR は `gh pr view <n> -R ks-kentem/<repo> --json closingIssuesReferences,state` で Issue にまとめ、Issue の state を `gh issue view` で**今の時点の値**として取る
- **レビューの正は提出日時**: ブラウザだけでしたレビューは作業ログに残らない（2026-11-16 は Approve 5 件のうち 3 件がログに無かった）。2 本目の search の候補それぞれについて、自分のレビューの `submitted_at` が対象日（JST）に入るかを確かめ、入るものだけを残す。自分の PR（スレッドへの返信もレビュー扱いで当たる）は除く
  ```bash
  gh api 'repos/ks-kentem/<repo>/pulls/<n>/reviews' --jq '[.[] | select(.user.login=="kentem-at-kato") | select(.submitted_at >= "<D-1>T15:00:00Z" and .submitted_at < "<D>T15:00:00Z") | .state] | join(",")'
  ```
  （`<D-1>` は対象日の前日。JST の 0 時は UTC の前日 15 時）
- 正式なレビューを出さず実機確認だけした PR は search に出ないので、作業ログを根拠に足す（状態は「実機確認まで」とし、5 節の要確認にも回す）
- レビューした PR は作成者（`author.login`）・自分のレビューの種別（APPROVED / COMMENTED / CHANGES_REQUESTED）・今の state を取る。報告では作成者を「〇〇さん」と姓で書く（作業ログの呼び方に合わせる。ログに出てこない人はログイン名の姓の部分を使う）

## 4. 組み立てる

出力の正本（2026-11-16 分でユーザーと合意した形）:

```
**11/16（月）作業報告**

**完了**
- #1272 測定項目の単位変更: PR 2 本をマージしてクローズ（指摘対応・衝突解消・Redmine 記載まで）
- #1270 社内規格値の一括設定: 指摘を修正してマージ、クローズ

**対応中**
- #1278 Excel のセル結合・並び順: Redmine 3 件を FE と BE で修正、実機確認済み → PR #1685 レビュー待ち
- #1571 写真管理基準の検索で道路か河川か見分けられない: 原因はパッケージが節などの階層を拾っていなかったこと。階層を表示するよう修正し、仮版を公開 → 今日、実機確認して PR を出す

**レビュー**
- 渡邊さんの PR 5 本: #1662・#1673・#1674・#1678 を Approve（いずれもマージ済み）、#1679 は実機確認まで
- 勝亦さんの PR 1 本（ks-sekisan-taikei-master-dialog #37）: Approve
```

（11/17 に作った最初の版はレビューが 3 本だった。上は 3 節の提出日時で拾い直した正しい版）

規則:
- 自分の担当分は **Issue 単位**、レビューは **PR 単位**（同じ作成者の PR はまとめる）
- Issue が今クローズ済みなら「完了」、開いていれば「対応中」。対応中には「→ 次の一手」を付ける。持ち越しの欄は作らない
- 題は Issue のタイトルを短く言い換える（「不具合修正⑯【優先度２】」のような接頭辞は落とす）
- **1 件 1 行**。Redmine の個別番号・検証の細部（テスト件数・変異テスト・ペルソナ名）・コミット SHA・ブランチ名は書かない
- Issue に紐づかない自分の PR や作業は、作業ログから Issue 番号が分かればその Issue の行にまとめる。分からなければ「**その他**」の見出しを足して 1 行で書く
- 該当がない見出し（例: レビューなし）は出さない。業務分が 0 件なら、引数なしのときは 1 節の祝日判定で前の平日へ戻る。引数で指定した日が 0 件なら「<D> の ks-kentem 分の作業ログ・GitHub 実績は見つからなかった」とだけ返す

## 5. gh で確かめられない事項は本文に書かない

作業ログにしか根拠がない状態（Redmine への投稿・実機確認の完了・口頭での合意など）は、作業ログの時点から変わっていることがある（2026-11-17、ログでは「投稿はこれから」の Redmine が実際は投稿済みだった）。報告本文には入れず、6 節の「要確認」に回す。本人が「済」と言えば、その場で本文に足して出し直す。

## 6. 出力

報告本文をそのままコピーできるように出し、その後ろに区切りを入れて次を短く添える:

- **要確認**: 5 節で回した事項と、2 節で判定できなかったログ。1 行ずつ、本文のどこに足すかの案つき
- **検証レベル**: Issue / PR の state は gh で確認した（いつの時点か）、作業内容は作業ログから拾った、の 2 行
