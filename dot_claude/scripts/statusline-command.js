// statusline-command.js - Claude Code statusline: model name / git branch / context usage / 利用枠の天気予報
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
const BLUE = '\x1b[2;34m';
const RED = '\x1b[2;31m';

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

// --- 利用枠（5h / 1w）の天気予報 -----------------------------------------------------------
// 消費ペースからリセット時点の使用率を予測し、天気で表す（2026-11-04 追加。Mod 版 usage-weather から移植）。
//   予測 = 使用率 × 窓の長さ ÷ max(経過, 窓の 10%)  ← 10% の下限はリセット直後に予測が跳ねるのを抑える
// 天気は予測と現在値の悪い方で決め、現在値 95% 以上は予測に関係なく台風。
// 記号は 1 文字幅のもの（絵文字は端末で幅がずれる）。

const MIN_MS = 60 * 1000;
const WINDOWS = {
  five_hour: { label: '5h', lengthMs: 300 * MIN_MS },
  seven_day: { label: '1w', lengthMs: 10080 * MIN_MS },
};
const MIN_ELAPSED_RATIO = 0.1;
const BANDS = [
  { below: 50, icon: '☀', word: '晴れ', color: YELLOW },
  { below: 80, icon: '☁', word: 'くもり', color: CYAN },
  { below: 100, icon: '☂', word: '雨', color: BLUE },
  { below: 130, icon: '☇', word: '雷雨', color: MAGENTA },
];
const TYPHOON = { icon: '↯', word: '台風', color: RED };
const WEEKDAYS = ['日', '月', '火', '水', '木', '金', '土'];

function weatherFor(projected, used) {
  if (used >= 95) return TYPHOON;
  const worst = Math.max(projected, used);
  return BANDS.find((b) => worst < b.below) || TYPHOON;
}

// limit: statusline JSON の rate_limits.<kind>（used_percentage, resets_at = epoch 秒）。
// 対象外の kind・使用率が数値でない枠は null。resets_at が無ければ予測せず現在値だけ。
function forecast(kind, limit, now) {
  const win = WINDOWS[kind];
  if (!win || !limit || typeof limit.used_percentage !== 'number' || !Number.isFinite(limit.used_percentage)) {
    return null;
  }
  const used = Math.round(limit.used_percentage);
  if (typeof limit.resets_at !== 'number' || !Number.isFinite(limit.resets_at)) {
    return { label: win.label, used, weather: weatherFor(used, used) };
  }
  const resetsAt = limit.resets_at * 1000;
  const remaining = Math.max(0, resetsAt - now);
  const elapsed = Math.max(win.lengthMs - remaining, win.lengthMs * MIN_ELAPSED_RATIO);
  const projected = Math.round((limit.used_percentage * win.lengthMs) / elapsed);
  return { label: win.label, used, projected, resetsAt, weather: weatherFor(projected, used) };
}

// 今日なら「15:30」、別の日なら「11/6(金)18:00」（実行環境のローカル時刻）
function resetText(resetsAt, now) {
  const r = new Date(resetsAt);
  const n = new Date(now);
  const hm = `${String(r.getHours()).padStart(2, '0')}:${String(r.getMinutes()).padStart(2, '0')}`;
  const isToday =
    r.getFullYear() === n.getFullYear() && r.getMonth() === n.getMonth() && r.getDate() === n.getDate();
  return isToday ? hm : `${r.getMonth() + 1}/${r.getDate()}(${WEEKDAYS[r.getDay()]})${hm}`;
}

// 例: 「☀ 5h 晴れ 12→35% ↺15:30」。天気の部分だけ天気の色、残りは DIM。
function forecastText(f, now) {
  const head = colorize(f.weather.color, `${f.weather.icon} ${f.label} ${f.weather.word}`);
  const nums = f.projected !== undefined ? ` ${f.used}→${f.projected}%` : ` ${f.used}%`;
  const reset = f.resetsAt !== undefined ? ` ↺${resetText(f.resetsAt, now)}` : '';
  return head + colorize(DIM, nums + reset);
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

  // Claude.ai サブスクの利用枠 (/usage 相当)。未契約 or 初回応答前は rate_limits が無く、
  // 枠ごとにも欠けうるので、ある枠だけ出す。
  const limits = input.rate_limits || {};
  const now = Date.now();
  const rl = Object.keys(WINDOWS)
    .map((kind) => forecast(kind, limits[kind], now))
    .filter(Boolean)
    .map((f) => forecastText(f, now))
    .join('  ');
  if (rl) parts.push(rl);

  process.stdout.write(parts.join(colorize(DIM, ' | ')) + '\n');
};

// テスト用に純粋関数を公開する（呼び出し形 require(...)() は変えない）
Object.assign(module.exports, { forecast, weatherFor, resetText });
