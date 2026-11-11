#!/usr/bin/env node
// skill-usage.js - スキルの利用実績を transcript から集計し、台帳へ統合して表示する（harness-audit Phase 3）
//
// transcript (~/.claude/projects/**/*.jsonl) は Claude Code の自動削除で約 30 日分しか残らないため、
// 集計結果を台帳へ「スキル → { セッション ID: 日付 }」で統合して期間を越えて残す。
// キーがセッション ID なので、何度実行しても数は二重にならない（冪等）。
// 台帳は Vault（Obsidian Sync で全 PC 共通）を正とし、Vault が無ければローカル state に置く。
// Vault パスは ~/.claude/skills/shared/integrations.md の vault / task_store_probe をミラー
// （claude-md-audit-reminder の .sh / .ps1 / run-hook.js と同じ。Vault を移したら grep で同時更新）。
//
// 数えるもの:
//   - assistant の tool_use で name === "Skill" の input.skill（自動起動・モデルからの起動）
//   - user メッセージ本文（文字列）の <command-name>/x</command-name>（手動起動）
// tool_result やツール入力の文字列に紛れた同じ文字列は数えない（コマンド文字列の自己参照を拾わないため）。
//
// 使い方: node skill-usage.js [--json]

'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

const HOME = os.homedir();
const PROJECTS = path.join(HOME, '.claude', 'projects');
const SKILLS = path.join(HOME, '.claude', 'skills');
const VAULT_PROBE = path.join(HOME, 'ObsidianVault', '.obsidian');
const LEDGER = fs.existsSync(VAULT_PROBE)
  ? path.join(HOME, 'ObsidianVault', '00_meta', 'skill-usage.json')
  : path.join(HOME, '.claude', 'state', 'skill-usage.json');
const EXCLUDE = new Set(['shared', 'synced']);
const CMD_RE = /<command-name>\/([A-Za-z0-9:_-]+)<\/command-name>/g;

function walk(dir, out = []) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const e of entries) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith('.jsonl')) out.push(p);
  }
  return out;
}

function userSkills() {
  const names = [];
  for (const e of fs.readdirSync(SKILLS, { withFileTypes: true })) {
    if (!e.isDirectory() || EXCLUDE.has(e.name) || e.name.endsWith('-workspace')) continue;
    const dir = path.join(SKILLS, e.name);
    if (fs.existsSync(path.join(dir, '.claude-plugin'))) continue; // Mod
    const md = path.join(dir, 'SKILL.md');
    if (!fs.existsSync(md)) continue;
    const manual = /^disable-model-invocation:\s*true/m.test(fs.readFileSync(md, 'utf8'));
    names.push({ name: e.name, manual });
  }
  return names.sort((a, b) => a.name.localeCompare(b.name));
}

function scan() {
  // hits: skill -> sessionId -> { date, kinds:Set }
  const hits = {};
  const add = (skill, sid, date, kind) => {
    const s = (hits[skill] ??= {});
    const h = (s[sid] ??= { date, kinds: new Set() });
    if (date > h.date) h.date = date;
    h.kinds.add(kind);
  };
  let oldest = null;
  for (const file of walk(PROJECTS)) {
    let text;
    try { text = fs.readFileSync(file, 'utf8'); } catch { continue; }
    if (!text.includes('"Skill"') && !text.includes('<command-name>')) {
      continue;
    }
    for (const line of text.split('\n')) {
      if (!line.includes('"Skill"') && !line.includes('<command-name>')) continue;
      let o;
      try { o = JSON.parse(line); } catch { continue; }
      const sid = o.sessionId || path.basename(file, '.jsonl');
      const date = (o.timestamp || '').slice(0, 10);
      if (!date) continue;
      if (!oldest || date < oldest) oldest = date;
      const c = o.message && o.message.content;
      if (o.type === 'assistant' && Array.isArray(c)) {
        for (const b of c) {
          if (b && b.type === 'tool_use' && b.name === 'Skill' && b.input && b.input.skill) {
            add(b.input.skill, sid, date, 'auto');
          }
        }
      } else if (o.type === 'user') {
        const texts = typeof c === 'string' ? [c]
          : Array.isArray(c) ? c.filter(b => b && b.type === 'text').map(b => b.text) : [];
        for (const t of texts) for (const m of t.matchAll(CMD_RE)) add(m[1], sid, date, 'manual');
      }
    }
  }
  return { hits, oldest };
}

function loadLedger() {
  try { return JSON.parse(fs.readFileSync(LEDGER, 'utf8')); } catch { return null; }
}

function main() {
  const asJson = process.argv.includes('--json');
  const today = new Date().toISOString().slice(0, 10);
  const host = os.hostname();
  const { hits, oldest } = scan();

  const ledger = loadLedger() || { version: 1, since: oldest || today, machines: {}, skills: {} };
  if (oldest && oldest < ledger.since) ledger.since = oldest;
  ledger.machines[host] = today;
  for (const [skill, sessions] of Object.entries(hits)) {
    // sessions[sid] = { d: 最終日付, k: 起動種別（m=手動 / a=自動）}
    const dst = (ledger.skills[skill] ??= { sessions: {} });
    for (const [sid, h] of Object.entries(sessions)) {
      const prev = dst.sessions[sid] || { d: h.date, k: '' };
      const kinds = new Set(prev.k);
      if (h.kinds.has('manual')) kinds.add('m');
      if (h.kinds.has('auto')) kinds.add('a');
      dst.sessions[sid] = { d: h.date > prev.d ? h.date : prev.d, k: [...kinds].sort().join('') };
    }
  }
  fs.mkdirSync(path.dirname(LEDGER), { recursive: true });
  const tmp = LEDGER + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(ledger, null, 1) + '\n');
  fs.renameSync(tmp, LEDGER);

  const days = Math.round((Date.parse(today) - Date.parse(ledger.since)) / 86400000);
  const rows = userSkills().map(({ name, manual }) => {
    const s = ledger.skills[name];
    const recs = s ? Object.values(s.sessions) : [];
    return {
      name, manualOnly: manual,
      sessions: recs.length,
      manualRuns: recs.filter(r => r.k.includes('m')).length,
      autoRuns: recs.filter(r => r.k.includes('a')).length,
      last: recs.length ? recs.map(r => r.d).sort().at(-1) : null,
    };
  });

  if (asJson) {
    console.log(JSON.stringify({ ledger: LEDGER, since: ledger.since, days, machines: Object.keys(ledger.machines), rows }, null, 1));
    return;
  }
  console.log(`台帳: ${LEDGER}`);
  console.log(`観測: ${ledger.since} から ${days} 日 / 記録した PC: ${Object.keys(ledger.machines).join(', ')}`);
  console.log('');
  console.log('skill\t手動専用\tセッション数\t(手動/自動)\t最終使用');
  for (const r of rows.sort((a, b) => a.sessions - b.sessions || a.name.localeCompare(b.name))) {
    console.log(`${r.name}\t${r.manualOnly ? 'yes' : '-'}\t${r.sessions}\t(${r.manualRuns}/${r.autoRuns})\t${r.last ?? '-'}`);
  }
}

main();
