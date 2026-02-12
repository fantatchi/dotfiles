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
const { existsSync } = require('fs');

module.exports = function (hookName) {
  const scriptsDir = join(homedir(), '.claude', 'scripts');

  if (process.platform === 'win32') {
    const ps1 = join(scriptsDir, hookName + '.ps1');
    if (!existsSync(ps1)) return;
    execSync(
      `powershell.exe -ExecutionPolicy RemoteSigned -NoProfile -File "${ps1}"`,
      { stdio: 'inherit' }
    );
  } else {
    const sh = join(scriptsDir, hookName + '.sh');
    if (!existsSync(sh)) return;
    execSync(`bash "${sh}"`, { stdio: 'inherit' });
  }
};
