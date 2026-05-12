# ADR フォーマット（Nygard / MADR）

SKILL.md「ADR で意思決定を分離」の補足。

## 形式の選択

ADR には主に 2 形式ある。プロジェクト規模・運用方針に応じて選ぶ:

| 形式 | 特徴 | 向くケース |
|---|---|---|
| **Nygard 形式** | シンプル（Status / Context / Decision / Consequences の 4 セクション）。原典。1 ADR 100〜300 行 | スタートアップ・中規模、軽量運用、最初の ADR 着手 |
| **MADR 形式** | 構造化（検討した選択肢 / 理由 / 結果の細分化を明示）。Nygard を拡張 | エンタープライズ・規制業界、トレードオフを詳細に残したい、選択肢比較を明示したい |

迷ったら **Nygard で始める**。後で詳細化が必要になったら個別 ADR を MADR 形式で書き直すか、選択肢比較セクションだけ追記する。

## 基本ルール（両形式共通）

- **1 ファイル 1 決定**: 1 つの ADR は 1 つの意思決定だけを扱う
- **追記しない・書き換えない**: 一度 Accepted にした ADR は変更しない。撤回するときは新しい ADR を作って `Superseded by ADR-NNNN` で繋ぐ（Status 行の書き換えだけは例外的に許容）
- **ファイル名は `ADR-NNNN-kebab-title.md`**: 連番 + 短いタイトル。NNNN は 4 桁ゼロ埋め
- **Consequences が最重要**: デメリットやトレードオフを正直に書くこと。これが将来の保守者への最大の贈り物

## 形式別の骨格

具体的なテンプレ全文（コピペ可能）は [templates.md の「ADR テンプレート」セクション](./templates.md#adr-テンプレートnygard-形式--シンプル版) を参照。本ファイルは「形式の選び方・運用ルール」を担う。

### Nygard 形式の特徴

- 4 セクション構成: Status / Context / Decision / Consequences
- Alternatives Considered は原典には含まれず、必要に応じて任意追記
- シンプルで書きやすい

### MADR 形式の特徴

- 構造化された 7 セクション: ステータス / 日付 / コンテキストと課題 / 検討した選択肢 / 決定 / 理由 / 結果
- 「検討した選択肢」を独立セクションとして強制
- トレードオフを詳細に残せる

## Status の遷移（両形式共通）

- **Proposed / 提案中**: 提案中。レビュー待ち
- **Accepted / 承認**: 承認済み。プロジェクトの方針として確定
- **Deprecated / 廃止**: 推奨されなくなった（後継がない場合）
- **Superseded by ADR-XXXX / 置き換え**: 後継 ADR に置き換えられた

Superseded する場合、新 ADR の `Context / コンテキストと課題` に「ADR-NNNN を見直す経緯」を書き、旧 ADR の Status を `Superseded by ADR-XXXX` に書き換える。

## 置き場所

- `docs/adr/ADR-NNNN-*.md` が一般的
- 用語集・本文からは相対リンクで参照
- README に「過去の意思決定は `docs/adr/` を参照」と入口を作る

## サイズ感

- Nygard: 1 ADR で 100〜300 行が標準
- MADR: 検討選択肢が多いと 200〜400 行になることもある
- いずれも 1 ページに収まらない場合は、複数の決定が混ざっている可能性 → 分割を検討

## いつ ADR を書くか

書く判断基準:

- **後任が「なぜこうしたのか」と聞きそうな決定** はすべて ADR 化
- 採用しなかった案を「採用しなかった理由つき」で残せるものは ADR 化
- ライブラリ選定 / アーキテクチャ層の分離方針 / データモデルの正規化方針 / 認証方式 などは典型

書かなくて良い判断基準:

- コードレベルの個別実装判断（コードコメント / PR description で十分）
- すぐ覆る暫定判断（**ただし「暫定である」こと自体を ADR 化することはある**）

## 関連リンク

- [Nygard "Documenting Architecture Decisions" (2011)](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) — 原典
- [MADR (Markdown Architectural Decision Records)](https://adr.github.io/madr/) — Nygard を拡張したテンプレート
- [ADR GitHub Organization](https://adr.github.io/) — 各種フォーマット集
- 具体的なテンプレ全文は [templates.md](./templates.md) の「ADR テンプレート」セクションを参照
