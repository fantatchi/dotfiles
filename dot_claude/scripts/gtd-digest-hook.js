// gtd-digest-hook.js - SessionStart hook (matcher: startup)
//
// 捕捉箱（tasks.md）の Inbox / Next を、その PC で 1 日 1 回だけユーザーへ表示する。
// /gtd-list を手で起動しないと捕捉箱を見る機会が無かったため（2026-11-04 追加）。
// - 表示の前に、チェック済み（- [x]）の行を Done へ移す（昇格。2026-11-25 追加）。
//   モバイルでチェックしても /gtd-list を実行しないと捕捉箱に残り続けたため。
//   Obsidian 起動中に書くと Sync で巻き戻ることがあるが、巻き戻っても行が元の場所へ戻るだけで
//   情報は消えないので受け入れる（翌日また移る）。書く直前に読み直し、変わっていたら見送る
// - 行を消す処理（Done の剪定）と @added 補完は /gtd-list の責務。ここでは剪定の時期を知らせるだけ
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

// チェック済みの行を Done の先頭へ移す。変換は gtd-list 2 節「チェック済みエントリの Done 昇格」と同じ。
// 移すものが無い・見出しが二重（Sync 競合の疑い）のときは、元の文字列をそのまま返す。
function promote(text, today) {
  const eol = text.includes('\r\n') ? '\r\n' : '\n';
  const lines = text.split(/\r?\n/);
  const heading = l => { const m = l.match(/^## (.+?)\s*$/); return m ? m[1] : null; };
  const names = lines.map(heading).filter(Boolean);
  if (new Set(names).size !== names.length) return { text, count: 0 };

  const kept = [], moved = [];
  let cur = null;
  for (const line of lines) {
    const h = heading(line);
    if (h) cur = h;
    const t = line.trim();
    if (!h && cur && cur !== 'Done' && /^- \[x\]/i.test(t)) {
      let body = t.replace(/^- \[x\]\s*/i, '').replace(/\s*@(added:\S+|captured-on-mobile)/g, '').trim();
      if (!/^\d{4}-\d{2}-\d{2} /.test(body)) body = `${today} ${body}`;
      moved.push(`- [x] ${body}`);
    } else {
      kept.push(line);
    }
  }
  if (!moved.length) return { text, count: 0 };

  const done = kept.findIndex(l => heading(l) === 'Done');
  if (done < 0) {
    // Done が無ければ末尾に作る（末尾の改行の有無は元に合わせる）
    const hasFinalEol = kept.length > 0 && kept[kept.length - 1] === '';
    while (kept.length && kept[kept.length - 1] === '') kept.pop();
    kept.push('', '## Done', '', ...moved);
    if (hasFinalEol) kept.push('');
  } else {
    // 見出し直後の空行は残し、その下（Done の先頭）へ入れる
    let at = done + 1;
    while (at < kept.length && kept[at].trim() === '') at++;
    kept.splice(at, 0, ...moved);
  }

  // 行を抜いた跡の連続空行を 1 つにまとめる
  const out = kept.filter((l, i) => !(l.trim() === '' && i > 0 && kept[i - 1].trim() === '' && i < kept.length - 1));
  return { text: out.join(eol), count: moved.length };
}

function digest(text, now, promoted = 0) {
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

  const active = Object.keys(sections).filter(s => s !== 'Done').flatMap(s => sections[s]);
  const checked = active.filter(l => /^- \[x\]/i.test(l)).length;
  const threshold = localDate(new Date(now.getTime() - OLD_DAYS * 86400000));
  // 剪定の時期: Done の完了日が保持期間（OLD_DAYS）より前の行（gtd-list 3 節のしきい値と同じく厳密に前）
  const prunable = (sections.Done || []).filter(l => {
    const m = l.match(/^- \[x\] (\d{4}-\d{2}-\d{2}) /i);
    return m && m[1] < threshold;
  }).length;
  if (!inbox.length && !next.length && !promoted && !prunable) return '';
  // Someday は寝かせる箱なので「古い」に数えない（数えると常に警告が出て、対処しても消えない）
  const aging = Object.keys(sections).filter(s => s !== 'Done' && s !== 'Someday').flatMap(s => sections[s]);
  const old = aging.filter(l => {
    const m = l.startsWith('- [ ]') && l.match(/@added:(\d{4}-\d{2}-\d{2})/);
    return m && m[1] < threshold;
  }).length;

  const out = ['📥 捕捉箱（今日の 1 回目の表示）', ...block('Inbox', inbox), ...block('Next', next)];
  if (promoted) out.push(`✅ チェック済みの ${promoted} 件を Done へ移しました`);
  // 昇格を見送った（見出しの二重化・読み直しで変化）ときだけ残る
  if (checked) out.push(`チェック済みが ${checked} 件残っています（/gtd-list で Done へ移ります）`);
  if (old) out.push(`⏳ 登録から ${OLD_DAYS} 日を超えたタスクが ${old} 件あります`);
  if (prunable) out.push(`🧹 Done に ${OLD_DAYS} 日を超えた完了が ${prunable} 件あります（/gtd-list で剪定）`);
  return out.join('\n');
}

function run() {
  try {
    const now = new Date();
    const today = localDate(now);
    if (shownToday(today)) return;
    if (!fs.existsSync(VAULT_PROBE) || !fs.existsSync(TASK_STORE)) return;
    let text = fs.readFileSync(TASK_STORE, 'utf8');
    let promoted = 0;
    const p = promote(text, today);
    // 書く直前に読み直し、他の writer（Obsidian・gtd-list）が書き換えていたら今回は見送る
    if (p.count && fs.readFileSync(TASK_STORE, 'utf8') === text) {
      fs.writeFileSync(TASK_STORE, p.text);
      text = p.text;
      promoted = p.count;
    }
    const msg = digest(text, now, promoted);
    // 出力より先に記録する（timeout で kill されても毎起動の再出力に陥らない側へ倒す）
    fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
    fs.writeFileSync(STATE_FILE, today);
    if (msg) process.stdout.write(JSON.stringify({ systemMessage: msg }));
  } catch (_) {
    // 起動を妨げない
  }
}

module.exports = { promote, digest, run };
if (require.main === module) run();
