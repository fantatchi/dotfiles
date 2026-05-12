# 最小汎用骨格（fallback）

既存仕様書が無い新規プロジェクト用の最小スケルトン。**既存があれば SKILL.md Step 1-3 でスタイル踏襲する方が望ましい**。

## HTML 骨格（CSS 最小）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{タイトル}}</title>
<style>
  :root { --bg:#fafaf9; --surface:#fff; --text:#1c1917; --muted:#57534e; --border:#e7e5e4; --accent:#6d28d9; --accent-bg:#ede9fe; }
  body { margin:0; background:var(--bg); color:var(--text); font-family:system-ui,sans-serif; line-height:1.65; }
  main { max-width:1000px; margin:0 auto; padding:40px 24px; }
  header.page { border-bottom:1px solid var(--border); padding-bottom:24px; margin-bottom:32px; }
  header.page h1 { font-size:26px; font-weight:600; margin:0 0 6px; }
  .tldr { background:var(--surface); border:1px solid var(--border); border-left:4px solid var(--accent); border-radius:6px; padding:14px 18px; }
  .tldr .label { display:inline-block; font-size:11px; font-weight:700; color:var(--accent); background:var(--accent-bg); padding:2px 8px; border-radius:3px; margin-bottom:8px; }
  section { margin:40px 0; }
  section > h2 { font-size:20px; font-weight:600; border-bottom:1px solid var(--border); padding-bottom:8px; }
  table { width:100%; border-collapse:collapse; border:1px solid var(--border); border-radius:6px; font-size:13px; }
  th, td { padding:10px 14px; text-align:left; border-bottom:1px solid var(--border); vertical-align:top; }
  thead th { background:#f5f5f4; }
</style>
</head>
<body>
<main>
  <header class="page">
    <h1>{{タイトル}}</h1>
    <div class="tldr">
      <span class="label">TL;DR</span>
      <p>{{2-3 行の要約}}</p>
    </div>
    <p>想定読者: {{...}} / 読了時間: 約 {{NN}} 分 / Status: Draft</p>
  </header>
  <section><h2>1. Context</h2><p>{{背景}}</p></section>
  <section><h2>2. Goals / Non-Goals</h2><h3>Goals</h3><ul><li>{{...}}</li></ul><h3>Non-Goals</h3><ul><li>{{...}}</li></ul></section>
  <section><h2>3. Design</h2><p>{{何を決めたか}}</p></section>
  <section><h2>4. Trade-offs</h2><table><thead><tr><th>案</th><th>採否</th><th>理由</th></tr></thead><tbody><tr><td>{{案A}}</td><td>採用</td><td>{{...}}</td></tr></tbody></table></section>
  <section><h2>5. Open Issues</h2><ul><li>{{...}}</li></ul></section>
</main>
</body>
</html>
```

## Markdown 要約骨格（HTML 主体プロジェクト用）

```markdown
# {{タイトル}}

> **Status**: Draft / Reviewed / Approved
> **HTML 版（詳細）**: [{{path}}.html]({{html path}})

## TL;DR
{{2-3 行}}

## 想定読者と読了時間
- **対象**: {{...}}
- **読了時間**: 約 {{NN}} 分

## 関連
- 関連 ADR: [{{ADR-NNNN}}]({{path}})
- 用語集: [{{path}}]({{path}})

## 改訂履歴
| 版 | 日付 | 内容 |
|---|---|---|
| v0.1 | YYYY-MM-DD | 初版 |
```

## Markdown 詳細骨格（MD 主体プロジェクト用）

```markdown
# {{タイトル}}

> **Status**: Draft / Reviewed / Approved
> **想定読者**: {{...}} / **読了時間**: 約 {{NN}} 分

## TL;DR

{{2-3 行の結論}}

## 1. Context（背景）

{{何を解こうとしているか、現状の課題}}

## 2. Goals / Non-Goals

### Goals
- {{やること}}

### Non-Goals
- {{あえてやらないこと}}

## 3. Design

{{何を決めたか}}

## 4. Trade-offs

| 案 | 採否 | 理由 |
|---|---|---|
| {{案A}} | 採用 | {{...}} |
| {{案B}} | 却下 | {{...}} |

## 5. Open Issues

- {{未確定事項}}

## 改訂履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v0.1 | YYYY-MM-DD | 初版 |
```

## 用語集エントリ形式

```markdown
### {{公式語}} ({{英語名 or フルスペル}})

**一言で言うと**: {{1-2 行}}

**詳細**:
- {{補足}}

**関連用語**: [{{他の用語}}](#anchor)

**出典**: [{{参照先}}]({{path}})
```

同義語は `→ **[公式語](#anchor)**` で公式語にリダイレクト（本文で別語を使わない）。

## ADR 骨格

ADR の骨格・Status 遷移・置き場ルールは [adr-format.md](adr-format.md) を参照。
