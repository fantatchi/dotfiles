# 推奨 docs/ ディレクトリ構成

`docs/` ディレクトリの推奨構成。プロジェクトに既存の構造がある場合は **既存構造を踏襲** すること（SKILL.md の Step 1 参照）。本ガイドはゼロから始める時の出発点。

## 基本パターン（md メイン）

```
docs/
├── README.md                    # 入口。「これは何で、どう動かすか」
├── glossary.md                  # 用語集（プロジェクト固有の言葉）
├── architecture/
│   ├── context.md               # C4 Level 1: システム全体像
│   ├── containers.md            # C4 Level 2: コンテナ構成
│   └── components/              # C4 Level 3: 必要な箇所だけ
├── adr/
│   ├── 0001-use-postgresql.md
│   ├── 0002-rest-to-grpc.md
│   └── ...
├── specs/
│   ├── functional/              # 機能仕様（画面・API・データ）
│   └── api/                     # OpenAPI で自動生成
└── runbook/                     # 運用手順（必要に応じて）
```

各ファイルの役割:

- **README.md**: 5 分で読める入口。詳細は他へリンク
- **glossary.md**: 用語の定義集。同義語の統一もここで
- **C4 図**: PlantUML または Structurizr DSL で記述し、自動レンダリング
- **ADR**: 1 決定 1 ファイル。連番管理
- **API 仕様**: 手で書かず OpenAPI から生成

## md + HTML 補足パターン

サマリー・概況・比較系を HTML 補足にする場合の構成:

```
docs/
├── README.md
├── glossary.md
├── architecture/                # md 中心
│   ├── context.md
│   ├── containers.md
│   └── components/
├── adr/                         # md 中心
│   └── *.md
├── specs/
│   ├── functional/              # md 中心
│   └── api/                     # OpenAPI 自動生成
├── _html/                       # HTML 補足ページ
│   ├── overview.html            # システム概要ランディング
│   ├── summary/                 # サマリー・概況ページ
│   │   ├── status.html
│   │   └── kpi.html
│   └── compare/                 # 比較・対比ページ
│       └── auth-options.html
└── runbook/
```

HTML 補足は **配置場所を `_html/` 配下に集約** すると、md 中心の運用と CI ビルドの境界が明確になる。

> **運用注意**: 手書き HTML は半年で腐るリスクがあるため、**本当に視覚情報が主役のページのみ** に限定する。md + Mermaid/PlantUML + ビルド生成（MkDocs / Docusaurus 等）で代替できる場合はそちらを優先。詳細は [workflow.md](./workflow.md#手書き-html-の運用警告重要) を参照。

## 既存プロジェクト用バリエーション

プロジェクトによっては以下のような構造になっている場合もある（既存に従う）:

### パターン A: カテゴリ別 + 連番

```
docs/
├── 01-overview.md
├── 02-architecture.md
├── 03-api.md
└── ...
```

### パターン B: HTML 主体（既存）

```
docs/
└── _html/
    ├── architecture/
    │   ├── 01-context.html
    │   └── 02-containers.html
    └── requirements/
        ├── 01-overview.html
        └── 02-glossary.html
```

### パターン C: md + html 並列

```
docs/
├── architecture/
│   ├── context.md
│   └── containers.md
└── _html/
    └── architecture/
        ├── context.html         # md からビルド生成 or 手書き補足
        └── containers.html
```

## 着手順序（ゼロから始める時）

完璧主義で全体を一気に作らない。以下の順で骨格を作る:

1. **README.md** — 5 分で読める入口を最初に
2. **glossary.md** — プロジェクト固有用語を 5〜10 個から
3. **architecture/context.md** — C4 Level 1（System Context）図
4. **adr/0001-*.md** — 最初の重要な意思決定を記録
5. **architecture/containers.md** — C4 Level 2（必要になったら）
6. **specs/** — 実装と並行して機能仕様を書く（事前に書きすぎない）

このパッケージで「全体像 / なぜ / 用語」の 3 つの詰まりポイントが最小コストでカバーできる。
