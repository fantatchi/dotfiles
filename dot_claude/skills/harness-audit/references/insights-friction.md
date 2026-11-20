# Phase 1 の材料: insights の摩擦記録

`/insights` は、セッションごとの摩擦（`friction_counts` / `friction_detail`）を `~/.claude/usage-data/facets/<session_id>.json` に残す。Phase 1 ではこれを「実際にどこで躓いたか」の材料として使う。

- facets は LLM がセッションを要約したもの。検証レベルは「推論」なので、そのまま提案にしない
- 使うのは facets の摩擦記録だけ。report.html の汎用提案（MCP の導入・headless など）は使わない。既存の判断と衝突しうるため（memory `feedback_adopt-external-guidance-by-diff`。例: GitHub MCP は 2026-08-27 に見送っている）
- facets が更新されるのは、ユーザーが `/insights` を手で実行したときだけ。usage-data はマシンごとに分かれていて、ここで見えるのはこのマシンの分だけ

## 1. 抽出

前回の `last_audit`（`~/ObsidianVault/00_meta/claude-state.md`）より後に始まったセッションのうち、摩擦があったものを出す。`SINCE=<epoch 秒>` を付けると基準を変えられる。

```bash
node -e '
const fs=require("fs"),H=process.env.HOME,p=H+"/.claude/usage-data/";
let since=process.env.SINCE;
if(!since){try{since=fs.readFileSync(H+"/ObsidianVault/00_meta/claude-state.md","utf8").match(/^last_audit:\s*(\d+)/m)[1]}catch{since="0"}}
const t0=Number(since)*1000;let n=0,latest=0;
for(const f of fs.existsSync(p+"facets")?fs.readdirSync(p+"facets"):[]){
  latest=Math.max(latest,fs.statSync(p+"facets/"+f).mtimeMs);
  const d=JSON.parse(fs.readFileSync(p+"facets/"+f));let m={};try{m=JSON.parse(fs.readFileSync(p+"session-meta/"+f))}catch{}
  const st=Date.parse(m.start_time||"");const k=Object.keys(d.friction_counts||{});
  if(!(st>=t0)||!k.length)continue;n++;
  console.log(`- ${m.start_time.slice(0,10)} ${d.session_id} [${k.join(",")}]\n  摩擦: ${d.friction_detail}\n  概要: ${d.brief_summary}`)}
console.log(`対象 ${n} 件（基準: ${new Date(t0).toISOString()} / facets 最終更新: ${latest?new Date(latest).toISOString().slice(0,10):"なし"}）`)'
```

0 件なら、提示に `- insights 由来 → 対象なし（facets 最終更新: <日付>）` の 1 行だけを書く。`/insights` の実行は求めない（記録があるときだけ使う材料という位置づけ）。

## 2. 突き合わせ

摩擦ごとに、CLAUDE.md・`~/.codex/AGENTS.md`・memory・context.md の判断メモ・該当するスキルと照らす。

- **手当て済みで、手当ての後には起きていない** → 落とす
- **手当て済みなのに再発した** → 散文を書き足す案ではなく、仕組み（hook やスキルの手順）に移す案を出す（memory `feedback_claude-md-audit-cant-know`）
- **手当てが無い** → 提案する。置き場所（CLAUDE.md / memory / スキル）も添える

## 3. 裏取り

提案に出す前に、該当セッションの transcript（`~/.claude/projects/*/<session_id>.jsonl`）で、摩擦が実際に起きたかを確かめる。transcript は約 30 日で消える。確かめられなかったものは「facets のみ・未確認」と明記する。

## 提示

Phase 1 の下に、他の提案と並べて `- （insights 由来・MM-DD）<摩擦の要約> → <案>` の形で書く。
