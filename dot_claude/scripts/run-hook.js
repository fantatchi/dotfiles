// run-hook.js - OS を判定して .sh / .ps1 を呼び分けるラッパー
//
// 使い方 (settings.json の hook command から):
//   node -e "require(require('os').homedir()+'/.claude/scripts/run-hook.js')('hook-name')"
//
// WSL/Linux/macOS → bash hook-name.sh
// Windows         → powershell.exe hook-name.ps1 (-EncodedCommand UTF-16LE base64)

const { execFileSync } = require('child_process');
const { homedir } = require('os');
const { join } = require('path');
const { existsSync, readFileSync } = require('fs');

module.exports = function (hookName) {
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
