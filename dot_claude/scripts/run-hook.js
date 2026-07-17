// run-hook.js - OS を判定して .sh / .ps1 を呼び分けるラッパー
//
// 使い方 (settings.json の hook command から):
//   node -e "require(require('os').homedir()+'/.claude/scripts/run-hook.js')('hook-name')"
//
// WSL/Linux/macOS → bash hook-name.sh
// Windows         → powershell.exe hook-name.ps1 (-EncodedCommand UTF-16LE base64)
//
// 軽量ゲート (2026-07-09 追加): Windows では毎プロンプトで hook ごとに
// node → powershell.exe の二段プロセス起動が走り、EDR/Defender のスキャン + 同時 spawn 競合で
// 各 hook が timeout 予算 (5/10/15s) を超えて全滅する事象があった。大半のプロンプトでは各 hook は
// debounce 済みの no-op なので、node 側で state ファイルを直接読んで「確実に no-op」と判定できる
// hook は powershell/bash を spawn せず即 return する。
//   - 判定不能・ファイル欠損・parse 失敗は必ず spawn (= 現行動作へフォールバック)。誤 skip で
//     reminder を握り潰さないための保守側デフォルト。
//   - ゲート定数は各 .ps1/.sh の SSOT をミラー。閾値変更時は 3 箇所 (.ps1 / .sh / ここ) を
//     grep で同時更新すること。ズレても node 側が大きめ = 余分に spawn するだけで安全側に倒れる。

const { execFileSync } = require('child_process');
const { homedir } = require('os');
const { join } = require('path');
const { existsSync, readFileSync } = require('fs');

const nowEpoch = Math.floor(Date.now() / 1000);

// state ファイルから先頭の連続数字 (epoch) を読む。無い/読めない/数字無しは 0。
function readEpoch(file) {
  try {
    const m = readFileSync(file, 'utf8').match(/\d+/);
    return m ? parseInt(m[0], 10) : 0;
  } catch (_) {
    return 0;
  }
}

// Vault 上の共有 state (claude-state.md) から監査実施時刻を読む。無い/未同期/parse 失敗は 0
// → 呼び出し側がローカル state へフォールバックする。
// frontmatter の `last_audit: <epoch>` のみを読む。`last_audit_at:` (ISO 併記・人間用) は
// キー名がコロンで区切られるため ^last_audit: にマッチせず、取り違えない。
// Vault パスは ~/.claude/skills/shared/integrations.md の vault / task_store_probe を SSOT として
// ミラー。Vault を移動したら .sh / .ps1 / ここの 3 箇所を grep で同時更新すること。
function readSharedAuditEpoch() {
  const vaultDir = join(homedir(), 'ObsidianVault');
  if (!existsSync(join(vaultDir, '.obsidian'))) return 0;
  try {
    const m = readFileSync(join(vaultDir, '00_meta', 'claude-state.md'), 'utf8')
      .match(/^last_audit:\s*(\d+)/m);
    return m ? parseInt(m[1], 10) : 0;
  } catch (_) {
    return 0;
  }
}

// hookName ごとの「確実に no-op なら true (= spawn 不要)」判定。gate が無い hook は常に spawn。
const gates = {
  // chezmoi-drift-reminder.{sh,ps1} のチェック間隔ゲートをミラー: 前回 check から 30 分未満なら
  // .sh/.ps1 は chezmoi status を実行せず無音 exit する。その shadow では powershell を起こさない。
  'chezmoi-drift-reminder'() {
    const CHECK_INTERVAL_MIN = 30; // mirror: chezmoi-drift-reminder.{sh,ps1}
    const lastCheck = readEpoch(
      join(homedir(), '.claude', 'state', 'chezmoi-drift', 'last-check.txt')
    );
    return lastCheck > 0 && (nowEpoch - lastCheck) / 60 < CHECK_INTERVAL_MIN;
  },
  // claude-md-audit-reminder.{sh,ps1} の閾値 + スヌーズをミラー: 経過 < 閾値、または overdue でも
  // 直近発火から 24h 未満なら無音 exit する。どちらも side-effect 無しの no-op なので skip 安全。
  'claude-md-audit-reminder'() {
    let thresholdDays = 7; // mirror: claude-md-audit-reminder.{sh,ps1}
    const envDays = parseInt(process.env.CLAUDE_MD_AUDIT_THRESHOLD_DAYS, 10);
    if (Number.isFinite(envDays) && envDays > 0) thresholdDays = envDays;
    const SNOOZE_MIN = 1440; // mirror: claude-md-audit-reminder.{sh,ps1}
    const stateDir = join(homedir(), '.claude', 'state', 'claude-md-audit');
    // 監査実施時刻は Vault (全 PC 共通の正) → ローカル (フォールバック) の順。script 側と同順。
    const lastAudit = readSharedAuditEpoch() || readEpoch(join(stateDir, 'last-audit.txt'));
    if (lastAudit <= 0) return false; // 初回/旧 state 移行は script 側に委ねる
    if ((nowEpoch - lastAudit) / 86400 < thresholdDays) return true; // 閾値未満 = no-op
    // overdue: スヌーズ中 (直近発火 < 24h) なら no-op
    const lastReminder = readEpoch(join(stateDir, 'last-reminder.txt'));
    return lastReminder > 0 && (nowEpoch - lastReminder) / 60 < SNOOZE_MIN;
  },
};

module.exports = function (hookName) {
  const gate = gates[hookName];
  if (gate) {
    try {
      if (gate()) return; // 確実に no-op → プロセスを起こさず即 return
    } catch (_) {
      // 判定中の想定外エラーは無視して spawn へフォールバック (安全側)
    }
  }

  const scriptsDir = join(homedir(), '.claude', 'scripts');

  if (process.platform === 'win32') {
    const ps1 = join(scriptsDir, hookName + '.ps1');
    if (!existsSync(ps1)) return;
    // PowerShell -EncodedCommand は UTF-16LE の base64 を要求する。
    // JS の文字列は内部 UTF-16 なので Buffer.from(str, 'utf16le') は
    // 各コードユニットを UTF-16LE バイト列として正しく書き出す。
    // （過去このコードを「バグ」と誤判定した指摘があったが、これが正しい実装）
    const script = readFileSync(ps1, 'utf8').replace(/^\uFEFF/, ''); // BOM除去
    const encoded = Buffer.from(script, 'utf16le').toString('base64');
    execFileSync(
      'powershell.exe',
      ['-ExecutionPolicy', 'RemoteSigned', '-NoProfile', '-EncodedCommand', encoded],
      { stdio: 'inherit' }
    );
  } else {
    const sh = join(scriptsDir, hookName + '.sh');
    if (!existsSync(sh)) return;
    // execFileSync でシェル経由を避ける（パスに空白等が含まれても安全）
    execFileSync('bash', [sh], { stdio: 'inherit' });
  }
};
