# プロジェクトルートの決め方（土台 = main checkout）

`.claude/` 配下の正本（context.md / tasks.md / handoff.md / progress.md / reviews/ / work/ など）を置くルートの決め方。context-save / context-load / pr-review / ks-standup / eli5 と hook（`scripts/context-save-hooks.js` / `scripts/context-inject.*`）が共通で使う。

## 規則

1. `git worktree list --porcelain` の 1 行目 `worktree <path>` を使う（main checkout = 土台）。worktree の中にいても土台が返る
2. 1 行目の次が `bare` なら（bare リポジトリ）、または git が失敗したら、`git rev-parse --show-toplevel`
3. git の外なら CWD

```bash
root=$(git worktree list --porcelain 2>/dev/null | awk 'NR==1{p=substr($0,10)} NR==2&&$1=="bare"{p=""} END{print p}')
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
```

worktree を使わないリポジトリでは `show-toplevel` と同じ結果になる。

## なぜ

worktree（`.claude/worktrees/<name>/`）は作業が終われば消す。`show-toplevel` は worktree 自身を返すので、そこへ書いた context.md や所見は worktree と一緒に消える（2026-11-27、cloud-cmp を「土台 + worktree」構成へ移したときに決めた）。

## 注意

- **コードを読む・git を打つ場所は今の作業場所（`show-toplevel` / CWD）のまま**。土台にするのは `.claude/` の正本の置き場所だけ。git の変化（保存後のコミットの有無など）も、今の作業場所で調べる
- 重要ファイルなどのパスは、土台からの相対で書く（worktree の中のファイルは `.claude/worktrees/<name>/...`）
- Windows の git で作った worktree を WSL から見ると、パスが `C:/...` になる。存在しなければ `wslpath -u` で変換する
