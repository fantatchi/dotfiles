// statusline-command.js - Claude Code statusline: model name / git branch / context usage
//
// 使い方 (settings.json の statusLine.command から):
//   node -e "require(require('os').homedir()+'/.claude/scripts/statusline-command.js')()"
//
// 2026-07-17 に bash + jq 実装 (~/.claude/statusline-command.sh) から移行。旧実装は
//   (a) スクリプト本体が ~/.claude/ 直下にあり powershell-utf8-profile.ps1 の $claudeInclude に
//       入っていないため Windows 側に SymLink されず、
//   (b) settings.json 側の `bash ~/.claude/...` は Windows で ~ の展開先も bash の解決先も不定、
//   (c) jq が別途必要、
// という 3 点で Windows 機では無表示だった。scripts/ 配下の Node 単一実装にすることで、
// scripts/ が既に SymLink 対象 = $claudeInclude 編集不要、かつ jq 依存も ~ 展開も消える。
// hook 群の run-hook.js と違い OS 分岐そのものが不要になるのでラッパーは噛ませない。

const { execFileSync } = require('child_process');
const { readFileSync } = require('fs');

// terminal は statusline を dim 表示するが、明示的に指定しておく
const DIM = '\x1b[2m';
const RESET = '\x1b[0m';
const CYAN = '\x1b[2;36m';
const YELLOW = '\x1b[2;33m';
const GREEN = '\x1b[2;32m';
const MAGENTA = '\x1b[2;35m';

function colorize(color, text) {
  return color + text + RESET;
}

// cwd が git work tree ならブランチ名を返す。非 git / detached HEAD / git 不在は ''。
function gitBranch(cwd) {
  if (!cwd) return '';
  try {
    return execFileSync('git', ['-C', cwd, '--no-optional-locks', 'branch', '--show-current'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch (_) {
    return '';
  }
}

// 数値なら四捨五入した文字列、それ以外 (undefined / null / 非数) は null。
// 呼び出し側は null をフィールドごと省略する条件に使う。
function pct(value) {
  return typeof value === 'number' && Number.isFinite(value) ? String(Math.round(value)) : null;
}

module.exports = function () {
  let input;
  try {
    input = JSON.parse(readFileSync(0, 'utf8'));
  } catch (_) {
    return; // stdin が読めない / JSON でない場合は無音 (statusline 非表示)
  }

  const parts = [];

  parts.push(colorize(CYAN, (input.model && input.model.display_name) || 'unknown'));

  const cwd = (input.workspace && input.workspace.current_dir) || input.cwd;
  const branch = gitBranch(cwd);
  if (branch) parts.push(colorize(YELLOW, branch));

  const ctx = pct(input.context_window && input.context_window.used_percentage);
  if (ctx !== null) parts.push(colorize(GREEN, `Ctx:${ctx}%`));

  // Claude.ai サブスクのレート制限使用率 (/usage 相当)。未契約 or 初回応答前は該当フィールドが
  // 無いので省略する。
  const limits = input.rate_limits || {};
  const five = pct(limits.five_hour && limits.five_hour.used_percentage);
  const week = pct(limits.seven_day && limits.seven_day.used_percentage);
  const rl = [five !== null ? `5h:${five}%` : null, week !== null ? `7d:${week}%` : null]
    .filter(Boolean)
    .join(' ');
  if (rl) parts.push(colorize(MAGENTA, rl));

  process.stdout.write(parts.join(colorize(DIM, ' | ')) + '\n');
};
