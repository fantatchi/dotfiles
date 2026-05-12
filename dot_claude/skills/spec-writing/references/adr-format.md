# ADR フォーマット（Nygard 形式）

SKILL.md「ADR で意思決定を分離」の補足。

## 基本ルール

- **1 ファイル 1 決定**: 1 つの ADR は 1 つの意思決定だけを扱う
- **追記しない・書き換えない**: 一度 Accepted にした ADR は変更しない。撤回するときは新しい ADR を作って `Superseded by ADR-NNNN` で繋ぐ（Status 行の書き換えだけは例外的に許容）
- **ファイル名は `ADR-NNNN-kebab-title.md`**: 連番 + 短いタイトル。NNNN は 4 桁ゼロ埋め

## 骨格

```markdown
# ADR-{{NNNN}}: {{決定タイトル}}

## Status
**Accepted** | Proposed | Deprecated | Superseded by ADR-XXXX

決定日: YYYY-MM-DD

## Context
{{なぜ決定が必要か、何が問題か、どんな制約があるか}}

## Decision
{{何を決めたか（短く明確に）}}

## Consequences
### Positive
- {{良いこと}}
### Negative
- {{悪いこと・トレードオフ}}

## Alternatives Considered
| 案 | 採否 | 理由 |
|---|---|---|
| {{案A}} | 採用 | （Decision 参照） |
| {{案B}} | 却下 | {{...}} |
```

## Status の遷移

- **Proposed**: 提案中。レビュー待ち
- **Accepted**: 承認済み。プロジェクトの方針として確定
- **Deprecated**: 推奨されなくなった（後継がない場合）
- **Superseded by ADR-XXXX**: 後継 ADR に置き換えられた

Superseded する場合、新 ADR の `Context` に「ADR-NNNN を見直す経緯」を書き、旧 ADR の Status を `Superseded by ADR-XXXX` に書き換える。

## 置き場所

- `docs/adr/ADR-NNNN-*.md` が一般的
- 用語集・本文からは相対リンクで参照
- README に「過去の意思決定は `docs/adr/` を参照」と入口を作る

## サイズ感

- 1 ADR で 100-300 行が標準
- 1 ページに収まらない場合は、複数の決定が混ざっている可能性 → 分割を検討

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
- [MADR (Markdown Any Decision Records)](https://adr.github.io/madr/) — Nygard を拡張したテンプレート
- [ADR GitHub Organization](https://adr.github.io/) — 各種フォーマット集
