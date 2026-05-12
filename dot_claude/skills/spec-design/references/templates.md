# 仕様書テンプレート集

**ドキュメントタイプ別の具体テンプレ**を集約。README / ADR / 用語集 / C4 / 簡易図 / HTML 補足ページなど、特定タイプを書くときの雛形。

既存プロジェクトに踏襲すべきスタイルがある場合は SKILL.md の「Step 1: 読み手と既存状態を確認」に従って **既存ファイルからコピー** すること。本テンプレは「ゼロから始めるとき」用。

## 関連ファイル

| ファイル | 役割 |
|---|---|
| **本ファイル** | ドキュメントタイプ別の具体テンプレ（README / ADR / 用語集 / C4 / Mermaid / HTML 補足） |
| [skeletons.md](./skeletons.md) | ドキュメント 1 枚の全体スケルトン（TL;DR / Context / Goals 構造） |
| [adr-format.md](./adr-format.md) | ADR の形式選択基準・Status 遷移・運用ルール |

---

## md テンプレート

### README.md

```markdown
# [プロジェクト名]

> 1〜2 文でシステムの目的を説明

## これは何か

このシステムが解決する課題を 3〜5 行で。誰のためのものか、何ができるか。

## アーキテクチャ概要

[C4 Level 1 図へのリンク]

主要コンポーネント:

- **コンポーネント A**: 役割
- **コンポーネント B**: 役割

## 開発を始める

### 前提

- 必要なツール、バージョン

### セットアップ

\`\`\`bash
# コマンドをそのまま貼れる形で
\`\`\`

### よくあるトラブル

- 症状 → 対処

## 運用

### 環境
- **開発環境**: [URL] / 認証: [SSO / 個別アカウント]
- **ステージング**: [URL] / 認証: [...]
- **本番**: [URL] / 認証: [...]

### 環境変数・シークレット

| 変数 | 用途 | 取得方法 |
|---|---|---|
| `DATABASE_URL` | DB 接続文字列 | Vault / 1Password / etc |
| `API_KEY` | 外部 API キー | 同上 |

### 監視・ダッシュボード

- **APM**: [Datadog / NewRelic / Grafana の URL]
- **ログ**: [CloudWatch / Loki / Elasticsearch の URL]
- **アラート**: [PagerDuty / Opsgenie / Slack channel]

### SLO・パフォーマンス目標

- 可用性: 99.X%
- レスポンスタイム p95: < NNN ms

### オンコール・障害連絡先

- **オンコール**: [PagerDuty schedule / Slack channel]
- **エスカレーション**: [連絡先]
- **障害対応 runbook**: [runbook/ へのリンク]

## ドキュメント

- [アーキテクチャ](./architecture/)
- [ADR 一覧](./adr/)
- [用語集](./glossary.md)
- [API 仕様](./specs/api/)

## 連絡先

担当チーム、Slack チャンネルなど
```

### ADR テンプレート（Nygard 形式 — シンプル版）

```markdown
# ADR-NNNN: [決定のタイトル（命令形で短く）]

## Status

提案中 / 承認 / 廃止 / 置き換え（→ ADR-XXXX）

## Context

何を決める必要があったか。背景となる事実、制約、組織的要因。

## Decision

何を決めたか。

## Consequences

この決定によって何が起きるか（良いことも悪いことも正直に）。
```

### ADR テンプレート（MADR 形式 — 構造化版）

```markdown
# ADR-NNNN: [決定のタイトル（命令形で短く）]

## ステータス

提案中 / 承認 / 廃止 / 置き換え（→ ADR-XXXX）

## 日付

YYYY-MM-DD

## コンテキストと課題

何を決める必要があったか。背景となる事実、制約、組織的要因。
ここで読者が「なぜこの決定が必要だったか」を理解できるように書く。

## 検討した選択肢

- 選択肢 A: 概要
- 選択肢 B: 概要
- 選択肢 C: 概要

## 決定

選択肢 X を採用する。

## 理由

なぜそれを選んだか。判断基準と各選択肢の評価。

## 結果（Consequences）

**ポジティブな影響:**

- ...

**ネガティブな影響・トレードオフ:**

- ...

**フォローアップで決める必要があること:**

- ...

## 関連

- 関連 ADR: ADR-XXXX
- 関連ドキュメント: ...
```

**重要**: ADR で最も価値があるのは「結果（Consequences）」セクション。デメリットやトレードオフを正直に書くこと。これが将来の保守者への最大の贈り物になる。Nygard / MADR の選択基準は [adr-format.md](./adr-format.md) を参照。

### 用語集テンプレート

```markdown
# 用語集

プロジェクト内で頻出する用語の定義。同義語・略語もここで統一する。

## ビジネス用語

### 注文（Order）

顧客がシステム上で確定させた購入意思のこと。

- 状態: pending / confirmed / shipped / delivered / cancelled
- 関連: カート（Cart）は確定前、注文は確定後

### カート（Cart）

購入確定前の商品リスト。

- 「ショッピングカート」「買い物かご」も同義で使われるが、コード・ドキュメント上は「Cart」で統一

## 技術用語

### 認証（Authentication）

ユーザーが本人であることを確認する処理。本プロジェクトでは JWT を使用。

- 認可（Authorization）とは区別する

### 認可（Authorization）

認証済みユーザーが特定の操作を行う権限を持つかの確認処理。

## 略語

| 略語 | 正式名称 | 説明 |
|------|---------|------|
| ADR | Architecture Decision Record | 設計判断記録 |
| SLA | Service Level Agreement | サービス品質保証 |
```

### C4 Level 1（System Context） — PlantUML

> **運用注意**: 外部 URL からの `!include` は **企業プロキシ / エアギャップ CI で失敗する** ことが多い。本番運用するときは以下のいずれかに切り替え:
> - **vendor 方式（推奨）**: `C4-PlantUML` リポジトリを `docs/c4/` 等に vendor / submodule して `!include ./c4/C4_Context.puml` でローカル参照
> - **キャッシュ方式**: 初回のみ外部 URL から取得して CI キャッシュに保持、以降はキャッシュ参照
> - **ミラー方式**: 社内 Artifact Repository（Nexus / Artifactory 等）にミラーを置き、`!include` 先をミラー URL に
>
> 以下のテンプレは「初学者向けに最短で動くもの」として外部 URL include を使用しているが、運用に乗せる前に上記方式へ切り替えること。

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

title System Context: [システム名]

Person(user, "エンドユーザー", "このシステムを使う人")
System(system, "[システム名]", "このシステムの役割を 1 行で")
System_Ext(external1, "外部システム A", "連携する外部サービス")

Rel(user, system, "[何をするか]")
Rel(system, external1, "[何を取得/送信するか]", "HTTPS/REST")

@enduml
```

### C4 Level 2（Container Diagram） — PlantUML

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title Container Diagram: [システム名]

Person(user, "ユーザー")

System_Boundary(system, "[システム名]") {
    Container(web, "Web アプリ", "React", "ユーザーインターフェース")
    Container(api, "API サーバ", "Node.js", "ビジネスロジック")
    ContainerDb(db, "データベース", "PostgreSQL", "永続化")
}

Rel(user, web, "利用", "HTTPS")
Rel(web, api, "API 呼び出し", "JSON/HTTPS")
Rel(api, db, "読み書き", "SQL/TCP")

@enduml
```

### 簡易フロー（Mermaid）

```mermaid
flowchart LR
    user[ユーザー] --> web[Web アプリ]
    web --> api[API サーバ]
    api --> db[(データベース)]
    api --> ext[外部サービス]
```

### シーケンス図（Mermaid）

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant W as Web
    participant A as API
    participant D as DB

    U->>W: 注文を確定
    W->>A: POST /orders
    A->>D: INSERT order
    D-->>A: order_id
    A-->>W: 201 Created
    W-->>U: 完了画面
```

---

## HTML 補足テンプレート

HTML 補足ページは **サマリー / 概況 / 比較・対比 / 配色で意味を伝える表** など、視覚情報が主役のページに限定して使う。視覚設計の判断は `dashboard-design` スキルを必ず参照すること。

### サマリーページの最小骨格

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>[システム名] サマリー</title>
  <style>
    :root {
      /* dashboard-design ガイドの配色パレットから選定 */
      --bg: #FFFFFF;
      --surface: #F5F5F5;
      --text: #1A1A1A;
      --muted: #6B7280;
      --accent: #2563EB;
      --warn: #D97706;
      --critical: #DC2626;
    }
    body { font-family: system-ui, sans-serif; color: var(--text); background: var(--bg); margin: 0; padding: 24px; }
    header.page { border-bottom: 1px solid var(--muted); padding-bottom: 16px; margin-bottom: 24px; }
    nav.breadcrumb { color: var(--muted); font-size: 14px; }
    h1 { margin: 8px 0 4px; }
    .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; }
    .card { background: var(--surface); padding: 16px; border-radius: 8px; }
    .card h3 { margin: 0 0 8px; font-size: 14px; color: var(--muted); text-transform: uppercase; }
    .card .value { font-size: 28px; font-weight: bold; }
  </style>
</head>
<body>
  <header class="page">
    <nav class="breadcrumb"><a href="../">Docs</a> / Summary</nav>
    <h1>[システム名]: 全体サマリー</h1>
    <p>このページで何が分かるかを 1 行で</p>
  </header>

  <section class="summary-grid">
    <div class="card">
      <h3>主要指標 1</h3>
      <div class="value">123</div>
    </div>
    <div class="card">
      <h3>主要指標 2</h3>
      <div class="value">45%</div>
    </div>
    <!-- 全体指標を左上に、詳細は右下に配置 -->
  </section>

  <footer>
    <nav class="page-nav">
      <a href="./detail-a.html">詳細 A</a> |
      <a href="./detail-b.html">詳細 B</a>
    </nav>
  </footer>
</body>
</html>
```

### 比較・対比ページの最小骨格

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>[項目] 比較</title>
  <style>
    :root {
      --bg: #FFFFFF;
      --surface: #F5F5F5;
      --text: #1A1A1A;
      --muted: #6B7280;
      --positive: #059669;
      --negative: #DC2626;
      --neutral: #6B7280;
    }
    body { font-family: system-ui, sans-serif; color: var(--text); padding: 24px; }
    table.compare { width: 100%; border-collapse: collapse; }
    table.compare th, table.compare td { padding: 12px; text-align: left; border-bottom: 1px solid var(--surface); }
    table.compare th { background: var(--surface); }
    .verdict.yes { color: var(--positive); font-weight: bold; }
    .verdict.no { color: var(--negative); font-weight: bold; }
    .verdict.partial { color: var(--neutral); }
  </style>
</head>
<body>
  <h1>[項目] の比較</h1>
  <p>何を判断するための比較表か（読み手のための一行）</p>

  <table class="compare">
    <thead>
      <tr>
        <th>観点</th>
        <th>選択肢 A</th>
        <th>選択肢 B</th>
        <th>選択肢 C</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>導入コスト</td>
        <td><span class="verdict yes">低</span></td>
        <td><span class="verdict partial">中</span></td>
        <td><span class="verdict no">高</span></td>
      </tr>
      <!-- 色だけで分類せず、テキスト（低/中/高）と色を二重符号化 -->
    </tbody>
  </table>

  <p><strong>結論</strong>: ... （比較から得られる推奨を 1〜2 行）</p>
</body>
</html>
```

**注意**: HTML 補足ページの配色・コントラスト比・色数制約・装飾排除・アクセシビリティの詳細は `dashboard-design` スキル + [`dashboard-design/references/visual-encoding.md`](../../dashboard-design/references/visual-encoding.md) を参照。本テンプレはあくまで最小骨格。
