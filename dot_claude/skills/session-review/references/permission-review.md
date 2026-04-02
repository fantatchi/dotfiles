# Phase 1: 権限レビュー 詳細手順

## Step 1: 手動承認の列挙

会話コンテキストを振り返り、以下を列挙する:

- ユーザーが「承認 (Allow)」したツール呼び出し
- ユーザーが「拒否 (Deny)」したツール呼び出し

各項目について記録: ツール種別 / 具体的な引数 / 承認or拒否

手動承認が一切なかった場合はこのフェーズをスキップ。

## Step 2: 保存先の確認

ユーザーに保存先を確認する:

- **プロジェクト単位**: `.claude/settings.local.json`（このリポジトリのみ）
- **ユーザー全体**: `~/.claude/settings.json`（全リポジトリ共通）

確認後、`Read` で対象ファイルを読み込み、現在の `permissions.allow` と `permissions.deny` を把握する。

## Step 3: グロブパターンの生成

手動承認されたツール呼び出しに対してグロブパターンを生成する。

### Bash コマンド

| コマンド例 | 提案パターン |
|-----------|-------------|
| `npm run check:type` | `Bash(npm run *)` |
| `git add components/foo.tsx` | `Bash(git add *)` |
| `mkdir -p .claude/reviews` | `Bash(mkdir *)` |
| `cat package.json` | 対象外（`Read` ツールを推奨） |

- 既存 `allow` でカバー済みなら「追加不要」と明記

### Edit / Write（必ずセットで提案）

| ファイルパス例 | 提案パターン |
|--------------|-------------|
| `.claude/skills/wrap-up/SKILL.md` | `Edit(.claude/skills/*)` + `Write(.claude/skills/*)` |
| `public/icons/arrow.svg` | `Edit(public/*)` + `Write(public/*)` |
| `.github/copilot-instructions.md` | `Edit(.github/*)` + `Write(.github/*)` |

- `Edit` / `Write` 両方が既存 `allow` にある場合のみ「追加不要」
- 片方だけ存在 → 不足分を追加候補に含める
- `deny` リストに含まれるパターンは絶対に提案しない
- 1ファイルのみならファイル単体パターンも選択肢として提示

## Step 4: 提案の収集

Step 1〜3 の結果を SKILL.md 本体の一括提示フォーマットに渡す。
個別確認はしない（SKILL.md 本体で全フェーズまとめて1回確認する）。

## 適用時のルール

ユーザー承認後、`Edit` で対象settingsの `permissions.allow` 配列に追記する際:

- 同種ルールの近くに配置（`Bash(...)` は既存 Bash の後、`Edit(...)` は既存 Edit の後）
- JSON 整合性を保持（インデント・カンマは既存スタイルに合わせる）
- `.env.local` や `*.pem` など機密ファイルへのアクセス権限は絶対に提案しない
- `Edit` / `Write` は必ずセットで追加
- `deny` 側で片方だけ deny → その旨を明記してセット追加を見送る
