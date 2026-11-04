// gtd-digest-hook.js - SessionStart hook (matcher: startup)
//
// 捕捉箱（tasks.md）の Inbox / Next を、その PC で 1 日 1 回だけユーザーへ表示する。
// /gtd-list を手で起動しないと捕捉箱を見る機会が無かったため（2026-11-04 追加）。
// - 読むだけ。Done 昇格・@added 補完は /gtd-list の責務なのでここでは書かない
// - systemMessage で表示し、モデルの文脈には入れない
// - 例外は全て握りつぶして無音 exit（起動を妨げない）
// Node のみで動く OS 共通実装（context-save-hooks.js と同じく .sh / .ps1 を持たない）。
const fs = require('fs');
const path = require('path');
const os = require('os');

// Vault パスは ~/.claude/skills/shared/integrations.md の task_store / task_store_probe をミラー。
// Vault を移動したら run-hook.js / claude-md-audit-reminder.{sh,ps1} と同時に grep で更新すること。
const VAULT_PROBE = path.join(os.homedir(), 'ObsidianVault', '.obsidian');
const TASK_STORE = path.join(os.homedir(), 'ObsidianVault', '00_meta', 'tasks.md');
const STATE_FILE = path.join(os.homedir(), '.claude', 'state', 'gtd-digest', 'last-shown.txt');
const OLD_DAYS = 30; // mirror: tasks-format.md「登録日と期間」
const MAX_LINES = 5;

function localDate(d) {
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function shownToday(today) {
  try { return fs.readFileSync(STATE_FILE, 'utf8').trim() === today; } catch (_) { return false; }
}

function parse(text) {
  const sections = {};
  let cur = null;
  for (const raw of text.split(/\r?\n/)) {
    const h = raw.match(/^## (.+?)\s*$/);
    if (h) { cur = h[1]; sections[cur] = sections[cur] || []; continue; }
    if (cur) sections[cur].push(raw.trim());
  }
  return sections;
}

function digest(text, now) {
  const sections = parse(text);
  const open = name => (sections[name] || []).filter(l => l.startsWith('- [ ]'));
  const clean = l => l.replace(/\s*@(added:\S+|captured-on-mobile)/g, '').trim();
  const block = (name, lines) => {
    if (!lines.length) return [`${name}: なし`];
    const shown = lines.slice(0, MAX_LINES).map(l => `  ${clean(l)}`);
    if (lines.length > MAX_LINES) shown.push(`  …ほか ${lines.length - MAX_LINES} 件`);
    return [`${name} ${lines.length} 件`, ...shown];
  };

  const inbox = open('Inbox'), next = open('Next');
  if (!inbox.length && !next.length) return '';

  const active = Object.keys(sections).filter(s => s !== 'Done').flatMap(s => sections[s]);
  const checked = active.filter(l => /^- \[x\]/i.test(l)).length;
  const threshold = localDate(new Date(now.getTime() - OLD_DAYS * 86400000));
  const old = active.filter(l => {
    const m = l.startsWith('- [ ]') && l.match(/@added:(\d{4}-\d{2}-\d{2})/);
    return m && m[1] < threshold;
  }).length;

  const out = ['📥 捕捉箱（今日の 1 回目の表示）', ...block('Inbox', inbox), ...block('Next', next)];
  if (checked) out.push(`チェック済みが ${checked} 件あります（/gtd-list で Done へ移ります）`);
  if (old) out.push(`⏳ 登録から ${OLD_DAYS} 日を超えたタスクが ${old} 件あります`);
  return out.join('\n');
}

function run() {
  try {
    const now = new Date();
    const today = localDate(now);
    if (shownToday(today)) return;
    if (!fs.existsSync(VAULT_PROBE) || !fs.existsSync(TASK_STORE)) return;
    const msg = digest(fs.readFileSync(TASK_STORE, 'utf8'), now);
    // 出力より先に記録する（timeout で kill されても毎起動の再出力に陥らない側へ倒す）
    fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
    fs.writeFileSync(STATE_FILE, today);
    if (msg) process.stdout.write(JSON.stringify({ systemMessage: msg }));
  } catch (_) {
    // 起動を妨げない
  }
}

module.exports = { digest, run };
if (require.main === module) run();
