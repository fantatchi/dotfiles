// run-hook.js - OS を判定して .sh / .ps1 を呼び分けるラッパー
//
// 使い方 (settings.local.json の hook command から):
//   node -e "require(require('os').homedir()+'/.claude/scripts/run-hook.js')('hook-name')"
//
// WSL/Linux → bash hook-name.sh
// Windows   → powershell.exe hook-name.ps1

const { execSync } = require('child_process');
const { homedir } = require('os');
const { join } = require('path');
const { existsSync, readFileSync } = require('fs');

module.exports = function (hookName) {
  const scriptsDir = join(homedir(), '.claude', 'scripts');

  if (process.platform === 'win32') {
    const ps1 = join(scriptsDir, hookName + '.ps1');
    if (!existsSync(ps1)) return;
    // UTF-8 で読み取り → UTF-16LE Base64 に変換して -EncodedCommand で渡す
    // これにより PowerShell のファイル読み込み時のエンコーディング問題を回避
    const script = readFileSync(ps1, 'utf8').replace(/^\uFEFF/, ''); // BOM除去
    const encoded = Buffer.from(script, 'utf16le').toString('base64');
    execSync(
      `powershell.exe -ExecutionPolicy RemoteSigned -NoProfile -EncodedCommand ${encoded}`,
      { stdio: 'inherit' }
    );
  } else {
    const sh = join(scriptsDir, hookName + '.sh');
    if (!existsSync(sh)) return;
    execSync(`bash "${sh}"`, { stdio: 'inherit' });
  }
};
