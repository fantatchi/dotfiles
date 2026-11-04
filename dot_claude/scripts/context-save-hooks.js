// 保存 hook の共通実装。Node.js のみで動作し、stdin / git 出力は UTF-8 で扱う。
// コマンドは実行せず、リテラルな git commit / gh pr create と対象ディレクトリを読む。
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const SELF_FILES = new Set(['context.md', 'tasks.md', 'handoff.md', 'progress.md']
  .map(name => `.claude/${name}`));
const COMMIT_FRESH_SEC = 120;
const DEBOUNCE_MIN = 15;
const THRESHOLD_MIN = 240;
const RESUME_DETECT_MIN = 60;

// 小さな共通部分だけを解析する。引用内の区切りは文字列として保持する。
// 展開・リダイレクト・複合構文に出会ったら、その先の本文をコマンド扱いしない。
// 既に読めた `git commit -m $(...)` 等のコマンド先頭は利用できる。
function commands(command, platform = process.platform) {
  const result = [];
  let words = [], value = '', started = false, literal = true, quote = '';
  const word = () => {
    if (started) words.push({ value, literal });
    value = ''; started = false; literal = true;
  };
  const finish = separator => {
    word();
    if (words.length) result.push({ words, separator });
    words = [];
  };
  for (let i = 0; i < command.length; i++) {
    const c = command[i], next = command[i + 1];
    if (quote === "'") {
      if (c === "'") {
        if (platform === 'win32' && next === "'") { value += c; i++; }
        else quote = '';
      } else value += c;
      continue;
    }
    if ((c === '$' && next === '(') || (c === '`' && platform !== 'win32') ||
        // Windows では Bash / PowerShell の両方が使われる。意味が異なる escape は解析を打ち切る。
        (platform === 'win32' && c === '\\' && next && /["';&|\s]/.test(next)) ||
        (!quote && /[<>(){}]/.test(c))) {
      // 動的なパスや command substitution 内部は評価しない。
      literal = false; finish('opaque'); return result;
    }
    const escape = platform === 'win32' ? '`' : '\\';
    if (c === escape && next !== undefined &&
        (!quote || platform === 'win32' || /[\\"$`\n]/.test(next))) {
      if (next !== '\n') { value += next; started = true; }
      i++; continue;
    }
    if (quote === '"') {
      if (c === '"') quote = '';
      else { value += c; if (c === '$') literal = false; }
    } else if (c === '"' || c === "'") {
      quote = c; started = true;
    } else if (c === '#' && !started) {
      while (i < command.length && command[i] !== '\n') i++;
      finish('\n');
    } else if (/[;&|\n]/.test(c)) {
      let separator = c;
      if (next === c && c !== '\n') { separator += next; i++; }
      finish(separator);
    } else if (/\s/.test(c)) word();
    else {
      value += c; started = true;
      if (c === '$' || c === '~' || /[*?\[\]]/.test(c)) literal = false;
    }
  }
  // 未閉鎖の引用符は壊れた入力なので捨てる。
  if (quote) return [];
  finish('');
  return result;
}

function events(command, cwd, platform = process.platform) {
  const paths = platform === 'win32' ? path.win32 : path.posix;
  const result = [];
  for (const { words, separator } of commands(command, platform)) {
    const args = words.map(w => w.value);
    if (!words[0].literal) continue;
    if (args[0] === 'cd' || (platform === 'win32' && args[0] === 'Set-Location')) {
      const index = args[1] === '--' ? 2 : 1;
      if (args.length !== index + 1 || !words[index].literal || ![';', '&&', '\n'].includes(separator)) break;
      cwd = paths.resolve(cwd, args[index]);
      continue;
    }
    if (/^git(?:\.exe)?$/i.test(args[0])) {
      let target = cwd, i = 1;
      for (; i < args.length;) {
        if (args[i] === '-C' && words[i + 1]?.literal) {
          target = paths.resolve(target, args[i + 1]); i += 2;
        } else if (args[i].startsWith('-C') && args[i].length > 2 && words[i].literal) {
          target = paths.resolve(target, args[i].slice(2)); i++;
        } else if (args[i] === '-c' && words[i + 1]?.literal) i += 2;
        else break;
      }
      if (args[i] === 'commit' && words[i].literal && !args.slice(i + 1).includes('--dry-run')) {
        result.push({ kind: 'コミット', cwd: target });
      }
    } else if (/^gh(?:\.exe)?$/i.test(args[0]) && args[1] === 'pr' && args[2] === 'create' &&
               words[1].literal && words[2].literal) {
      result.push({ kind: 'PR 作成', cwd });
    }
  }
  return result;
}

function git(cwd, args) {
  try {
    return execFileSync('git', ['-C', cwd, ...args], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true,
      timeout: 3000, maxBuffer: 8 * 1024 * 1024,
    });
  } catch (_) { return null; }
}

function readUpdated(root) {
  const content = fs.readFileSync(path.join(root, '.claude', 'context.md'), 'utf8');
  const frontmatter = content.match(/^\uFEFF?---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  const value = frontmatter?.[1].match(/^updated:[ \t]*(.+?)[ \t]*\r?$/m)?.[1];
  return value ? Date.parse(value.replace(/^(['"])(.*)\1$/, '$2')) : NaN;
}

function gitTrigger(input, { cwd = process.cwd(), now = Date.now() } = {}) {
  const command = input.tool_input?.command;
  if (typeof command !== 'string') return '';
  const notifications = new Map();
  for (const event of events(command, cwd)) {
    const root = git(event.cwd, ['rev-parse', '--show-toplevel'])?.trim();
    if (!root) continue;
    let updated;
    try { updated = readUpdated(root); } catch (_) { continue; }
    if (Number.isFinite(updated) && now - updated < DEBOUNCE_MIN * 60000) continue;
    if (event.kind === 'コミット') {
      const epoch = Number(git(root, ['log', '-1', '--format=%ct'])?.trim());
      const age = now / 1000 - epoch;
      if (!epoch || age < 0 || age > COMMIT_FRESH_SEC) continue;
    }
    // HEAD 時刻による推定を維持。コマンド全体の出力だけでは個別の成否は断定できない。
    notifications.set(root, `${event.kind}の操作後です。対象リポジトリ: ${JSON.stringify(root)}。ユーザーへの報告の前に、このリポジトリを対象として context-save スキルを実行し、最新状態を .claude/context.md に保存してください。`);
  }
  if (!notifications.size) return '';
  return JSON.stringify({ hookSpecificOutput: {
    hookEventName: 'PostToolUse', additionalContext: [...notifications.values()].join('\n'),
  } });
}

// porcelain v1 -z はパスを引用・エスケープせず返す。rename/copy は移動先、移動元の順。
function statusPaths(output) {
  const records = output.split('\0'), paths = [];
  for (let i = 0; i < records.length; i++) {
    const record = records[i];
    if (record.length < 4) continue;
    paths.push(record.slice(3));
    if (/[RC]/.test(record.slice(0, 2))) i++;
  }
  return paths;
}

function hasChangeSinceSave(root, updated) {
  if (git(root, ['log', `--since=@${Math.floor(updated / 1000)}`, '--oneline', '-n', '1'])?.trim()) return true;
  const status = git(root, ['status', '--porcelain=v1', '-z', '--untracked-files=all']);
  if (status === null) return false;
  for (const name of statusPaths(status)) {
    if (SELF_FILES.has(name)) continue;
    try {
      if (fs.lstatSync(path.join(root, name)).mtimeMs > updated) return true;
    } catch (error) {
      if (error.code === 'ENOENT') return true; // 削除には mtime がない。
    }
  }
  return false;
}

function sessionStart(input, home, now) {
  const dir = path.join(home, '.claude', '.session-markers');
  try {
    fs.mkdirSync(dir, { recursive: true });
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (!entry.isFile()) continue;
      const file = path.join(dir, entry.name);
      if (now - fs.statSync(file).mtimeMs > 8 * 86400000) fs.unlinkSync(file);
    }
  } catch (_) { /* マーカーの保存・掃除は best-effort。 */ }
  if (typeof input.session_id !== 'string' || !input.session_id) return 0;
  const safeId = input.session_id.replace(/[^A-Za-z0-9._-]/g, '_').slice(0, 128);
  if (safeId === '.' || safeId === '..') return 0;
  const file = path.join(dir, safeId);
  try {
    const reset = () => fs.writeFileSync(file, String(Math.floor(now / 1000)));
    if (!fs.existsSync(file)) { reset(); return null; }
    const mtime = fs.statSync(file).mtimeMs;
    if (now - mtime >= RESUME_DETECT_MIN * 60000 ||
        /^\s*[/$]context-load\b|<command-name>\/context-load<\/command-name>/.test(input.prompt || '')) {
      reset(); return null;
    }
    const value = fs.readFileSync(file, 'utf8').trim();
    let start = /^\d+$/.test(value) ? Number(value) * 1000 : mtime;
    if (start > now) { start = now; reset(); }
    fs.utimesSync(file, new Date(now), new Date(now));
    return start;
  } catch (_) { return 0; }
}

function reminder(input, { cwd = process.cwd(), home = os.homedir(), now = Date.now() } = {}) {
  const start = sessionStart(input, home, now);
  if (start === null) return '';
  const root = git(cwd, ['rev-parse', '--show-toplevel'])?.trim();
  if (!root) return '';
  let updated;
  try { updated = readUpdated(root); } catch (_) { return ''; }
  if (!Number.isFinite(updated)) return '';
  const minutes = Math.floor((now - Math.max(updated, start)) / 60000);
  if (minutes < THRESHOLD_MIN || !hasChangeSinceSave(root, updated)) return '';
  return `<system-reminder>
最後の context 保存またはセッション開始から ${minutes} 分経過し、保存後の変更があります（閾値: ${THRESHOLD_MIN} 分）。
このターンの応答に入る前に context-save スキルを実行して、判断メモ・次のステップを含めた最新状態を .claude/context.md に書き出してください。
保存が終わったら、続けてユーザーの本来のリクエストに応答してください。
</system-reminder>`;
}

function run(name) {
  let input;
  try { input = JSON.parse(fs.readFileSync(0, 'utf8')); } catch (_) { return; }
  if (!input || typeof input !== 'object') return;
  const output = name === 'context-save-git-trigger' ? gitTrigger(input)
    : name === 'context-save-reminder' ? reminder(input) : '';
  if (!output) return;
  // Claude Code から呼ばれたときだけ、保存リマインダーを JSON の additionalContext で出す（2026-11-04）。
  // plain text は「hook 成功メッセージ」として別枠で渡り、Mod（context-autosave）が横取りできないため。
  // Codex も同じ hook を共有しており、JSON 形式を受け付けるか未確認なので、CLAUDECODE が無いときは従来どおり。
  if (name === 'context-save-reminder' && process.env.CLAUDECODE) {
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: { hookEventName: 'UserPromptSubmit', additionalContext: output },
    }) + '\n');
    return;
  }
  process.stdout.write(output + '\n');
}

module.exports = { events, statusPaths, gitTrigger, reminder, hasChangeSinceSave, run };
if (require.main === module) run(process.argv[2]);
