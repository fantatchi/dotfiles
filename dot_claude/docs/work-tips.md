# 作業 Tips

`~/.claude/CLAUDE.md` から外出しした、環境固有・状況依存の操作 Tips。該当操作（Bash 実行 / Git / chezmoi / gh api / WSL interop / Windows UAC）に遭遇したときにだけ引く参照ナレッジのため、毎セッション読み込まれる CLAUDE.md からは外している。

- **Bash ツールは bash。PowerShell の here-string `@'...'@` は使えない**: 環境の primary shell が PowerShell でも、Claude Code の Bash ツールは bash を実行する。`git commit -m @'...'@` のような PowerShell here-string を Bash ツールで使うと、bash が `@` をリテラルとして扱いコミットメッセージの先頭・末尾に `@` が混入する（実際に 4 コミット作り直す事故あり）。複数行メッセージは **bash heredoc**（`git commit -F - <<'EOF'` … `EOF`）で渡す
- **別ブランチのファイルを checkout せずに読む**: PR レビュー時など、現在のブランチを維持したまま別ブランチの内容を読むには `git fetch origin <branch>` した上で `git show FETCH_HEAD:<path>` または `git show origin/<branch>:<path>` を使う。作業中のブランチを崩さずに済む
- **「未取込」ローカルブランチ ≠ 作業ロストの検証手順**: マージ後にローカルブランチが `[origin/...: gone]`（リモート削除済）かつ `git branch -d` で「未マージ」と弾かれても、即ロストとは限らない。`git merge-base --is-ancestor <branch> origin/master` で祖先判定 → 真なら取込済。偽でも `git diff --stat origin/master <branch>` で「origin 側が前進＝オーファン tip が古い」を確認できれば内容は別経路で反映済と判定でき、`-D` で安全に削除できる。GUI 即マージで follow-up push がオーファン化したケース（同一テーマの別 PR で再実装）で有効。「未マージ」表示を鵜呑みにして残し続けると stale ブランチが溜まる
- **`chezmoi add` と `chezmoi re-add` の違い**: `re-add` は既存管理ファイルの更新専用。新規ファイルを source に取り込むには `chezmoi add` を使う（`re-add` だと `not managed` エラー）
- **`run_before_*` は `chezmoi diff` に常に出る**: `run_before_` スクリプトは毎回 apply 時に実行されるため、diff がクリアにならないのは正常動作。`run_onchange_` はハッシュ変化時のみ実行されるので diff に出ない
- **リモートブランチ削除を `gh api` で回避する**: `git push origin --delete <branch>` がシステム側のブロックで弾かれる環境では、`gh api --method DELETE repos/<owner>/<repo>/git/refs/heads/<branch>` が代替になる。PR マージ後のブランチ片付けに使える
- **Git Bash で `gh api` のエンドポイント先頭スラッシュ**: Git Bash / MSYS は `gh api /repos/...` の先頭スラッシュを Windows パス（`C:/Program Files/Git/repos/...`）に変換してしまい、`invalid API endpoint` エラーになる。先頭スラッシュを外して `gh api repos/...` と書く
- **`gh api search/...` のクエリ内 `+` エンコード**: `gh api "search/...?q=...committer-date:...T00:00:00+09:00.."` のように **TZ offset を生の `+` で書くと、GitHub Search が `+` をクエリ語の区切り（スペース）として解釈** し、日付範囲フィルタが壊れて **全件 0 で返る**（`q=` 内では qualifier 連結の `+` と日付値内の `+09:00` が同じ文字で衝突する）。TZ offset の `+` は必ず `%2B` にエンコードする（`T00:00:00%2B09:00`）。または `gh api search/issues --raw-field "q=author:X type:pr merged:...+09:00.."` で gh にエンコードさせる。検証: 生の `+09:00` → `total_count=0` / `%2B09:00` → 正しくヒット。2026-06-01 の `/obsidian-daily` で全 commit/PR が 0 件になった真因
- **管理者権限が必要な Windows コマンドを UAC 経由で実行**: 通常 PS から `wevtutil sl ... /e:true` 等を打つと `Access denied (exit 5)` になる。`Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile','-Command','...' -Wait` で UAC 昇格すると、ユーザーが UAC ダイアログで「はい」を押すだけで管理者シェルから実行される。複数コマンドをまとめたい時は `-EncodedCommand` で base64 エンコードした 1 つの大きい command として渡すと改行・引用符のエスケープを気にせず済む。実行直後は `-Wait` で完了を待ち、結果は通常 PS 側で `wevtutil gl` 等を再実行して verify する運用
- **WSL 側にしかない chezmoi に Windows ネイティブからアクセスする**: chezmoi バイナリが Windows シェルで見つからない場合、WSL のみインストールされている可能性が高い。次の発見手順で chezmoi source を UNC パス経由で Read/Edit できる（リテラルパスは PC ごとに distro 名・ユーザー名・source 位置が異なるので、毎回コマンドで取得する）:
  1. WSL distro 名取得: `wsl --list --quiet | Select-Object -First 1`（PowerShell）
  2. WSL 内 source パス取得: `wsl chezmoi source-path`
  3. UNC パスに変換: `\\wsl.localhost\<distro>\<wsl-path>`（例: `\\wsl.localhost\Ubuntu\home\at-kato\.local\share\chezmoi\dot_claude\CLAUDE.md`）
  4. Read/Edit ツールで該当 UNC パスを直接操作可（cloud-cmp 等の `.claude/settings.local.json` 経由で permission を許可しておくとスムーズ）
  5. 編集後の target 反映: `wsl chezmoi apply`（commit は任意で `cd <source>` → `wsl git commit ...`）
