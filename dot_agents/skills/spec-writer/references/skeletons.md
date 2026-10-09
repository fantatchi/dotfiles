# 最小汎用骨格（fallback）

既存仕様書が無い新規プロジェクト用の **ドキュメント全体の最小骨格**。**既存があれば SKILL.md Step 1-3 でスタイル踏襲する方が望ましい**。

## 本ファイルと templates.md の責務分離

| ファイル | 担うもの | 利用シーン |
|---|---|---|
| **skeletons.md（本ファイル）** | ドキュメント 1 枚の全体スケルトン（TL;DR / Context / Goals / Design / Trade-offs などのページ構造） | 「プロジェクトに既存ドキュメントが何もない、ゼロからこの 1 枚を作る」 |
| **[templates.md](./templates.md)** | ドキュメントタイプ別の具体テンプレ（README / ADR Nygard・MADR / 用語集 / C4 PlantUML / 簡易図 / HTML 補足ページ） | 「特定タイプのドキュメント（例: ADR）を書く、その雛形が欲しい」 |

迷ったら **templates.md を先に見る**（具体テンプレが揃っている）。templates.md でカバーされない汎用ページを書くときに本ファイルを参照する。

## HTML 骨格（CSS 最小）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{タイトル}}</title>
<style>
  /* DADS v2.0.1 準拠 (HEX 出典: references/dads-tokens.md)。影と角丸カードは使わず、罫線と余白で区切る */
  :root { --bg:#ffffff; --surface:#f2f2f2; --text:#1a1a1a; --muted:#4d4d4d; --border:#e6e6e6; --accent:#264af4; --accent-deep:#0017c1; --accent-bg:#e8f1fe; --accent-line:#c5d7fb; }
  body { margin:0; background:var(--bg); color:var(--text); font-family:'Noto Sans JP','BIZ UDPGothic',system-ui,sans-serif; line-height:1.8; }
  main { max-width:880px; margin:0 auto; padding:48px 20px 96px; }
  header.page { margin-bottom:32px; }
  header.page h1 { font-size:32px; font-weight:700; line-height:1.4; margin:0 0 12px; }
  header.page .meta { font-size:13px; color:var(--muted); padding-block:10px; border-block:1px solid var(--border); }
  a { color:var(--accent-deep); text-decoration:underline; }
  .tldr { background:var(--accent-bg); border:1px solid var(--accent-line); border-radius:8px; padding:18px 24px; }
  .tldr .label { display:block; font-size:13px; font-weight:700; color:var(--accent-deep); margin-bottom:4px; }
  .tldr p { margin:0; }
  section { margin-top:56px; }
  section > h2 { font-size:24px; font-weight:700; border-bottom:1px solid var(--border); padding-bottom:10px; }
  table { width:100%; border-collapse:collapse; font-size:14px; }
  th, td { padding:10px 14px; text-align:left; border-bottom:1px solid var(--border); vertical-align:top; }
  thead th { font-size:13px; color:var(--muted); border-bottom-color:#cccccc; }
</style>
</head>
<body>
<main>
  <header class="page">
    <h1>{{タイトル}}</h1>
    <p class="meta">想定読者: {{...}} / 読了時間: 約 {{NN}} 分 / Status: Draft</p>
  </header>
  <div class="tldr">
    <span class="label">要点</span>
    <p>{{2-3 行の要約}}</p>
  </div>
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

## 用語集エントリ形式・ADR 骨格

これらの具体テンプレは責務分離のため [templates.md](./templates.md) に集約しています:

- 用語集テンプレ（カテゴリ別 + 同義語リダイレクト方式）
- ADR テンプレ（Nygard 形式 / MADR 形式）

ADR の Status 遷移・置き場ルール・形式選択基準は [adr-format.md](./adr-format.md) を参照。
