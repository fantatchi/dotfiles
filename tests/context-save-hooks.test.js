// Linux: node --test tests/context-save-hooks.test.js
// Windows: node.exe --test tests/context-save-hooks.test.js (Git for Windows が必要)
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');
const hooks = require('../dot_claude/scripts/context-save-hooks.js');
const scripts = path.resolve(__dirname, '../dot_claude/scripts');

function fixture(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'context-hooks-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const repo = path.join(dir, '日本語 repo'), home = path.join(dir, 'home');
  fs.mkdirSync(repo); fs.mkdirSync(home);
  const empty = path.join(dir, 'empty'); fs.mkdirSync(empty);
  const config = path.join(dir, 'gitconfig'); fs.writeFileSync(config, '');
  const env = { ...process.env, HOME: home, USERPROFILE: home,
    GIT_CONFIG_GLOBAL: config, GIT_CONFIG_NOSYSTEM: '1',
    GIT_AUTHOR_NAME: 'Test', GIT_COMMITTER_NAME: 'Test',
    GIT_AUTHOR_EMAIL: 'user1@example.com', GIT_COMMITTER_EMAIL: 'user1@example.com',
  };
  const git = (args, extra = {}) => execFileSync('git', ['-C', repo, ...args], {
    env: { ...env, ...extra }, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'],
  });
  git(['init', '-q', '--template=' + empty]);
  git(['config', 'core.hooksPath', empty]);
  // 実環境の Git 設定にもフックにも依存しないテストリポジトリ。
  git(['commit', '--allow-empty', '-qm', 'fixture'], {
    GIT_AUTHOR_DATE: '2020-01-01T00:00:00+00:00', GIT_COMMITTER_DATE: '2020-01-01T00:00:00+00:00',
  });
  fs.mkdirSync(path.join(repo, '.claude'));
  const now = Date.now(), saved = now - 5 * 3600000;
  const context = (timestamp = saved) => fs.writeFileSync(path.join(repo, '.claude/context.md'),
    `---\r\nupdated: "${new Date(timestamp).toISOString()}"\r\n---\r\n`);
  context();
  const markerDir = path.join(home, '.claude/.session-markers');
  fs.mkdirSync(markerDir, { recursive: true });
  const marker = path.join(markerDir, 'session');
  const active = () => {
    fs.writeFileSync(marker, String(Math.floor((now - 6 * 3600000) / 1000)));
    fs.utimesSync(marker, new Date(now), new Date(now));
  };
  active();
  const write = (name, timestamp) => {
    const file = path.join(repo, name); fs.writeFileSync(file, 'fixture');
    fs.utimesSync(file, new Date(timestamp), new Date(timestamp));
    return file;
  };
  const run = (name, input, cwd = repo) => spawnSync(process.execPath,
    ['-e', `require(${JSON.stringify(path.join(scripts, 'run-hook.js'))})(${JSON.stringify(name)})`],
    { cwd, env, input: JSON.stringify(input), encoding: 'utf8' });
  return { dir, repo, home, env, git, now, saved, context, marker, active, write, run };
}

test('引用内・コメント・here document のコマンド文字列は通知対象にしない', () => {
  for (const platform of ['linux', 'win32']) {
    for (const command of [
      'printf "%s" "; gh pr create --title example"',
      "echo 'git commit; gh pr create'", 'echo "first\ngit commit"',
      '# gh pr create\necho ok', 'cat <<EOF\ngh pr create\nEOF',
      'echo "$(git commit; gh pr create)"',
      String.raw`echo "\"; gh pr create; echo \""`,
    ]) assert.deepEqual(hooks.events(command, '/repo', platform), [], command);
  }
});

test('実際のコマンド先頭と区切り、複数の -C、cd を認識する', () => {
  assert.deepEqual(hooks.events('git -C "../other repo" -C sub commit -m "; gh pr create"', '/work/repo', 'linux'),
    [{ kind: 'コミット', cwd: '/work/other repo/sub' }]);
  assert.deepEqual(hooks.events('cd "../other repo" && git commit -m ok\ngh pr create', '/work/repo', 'linux'),
    [{ kind: 'コミット', cwd: '/work/other repo' }, { kind: 'PR 作成', cwd: '/work/other repo' }]);
  assert.equal(hooks.events('git commit -m "$(cat <<\'EOF\nmessage\nEOF\n)"', '/repo', 'linux').length, 1);
  assert.deepEqual(hooks.events('git -C "$repo" commit', '/repo', 'linux'), []);
  assert.deepEqual(hooks.events('git commit --dry-run', '/repo', 'linux'), []);
});

test('Windows のドライブ・UNC・空白・日本語パスを保持する', () => {
  for (const target of ['C:\\work tree\\日本語', '\\\\server\\share\\repo', 'D:/work tree/repo']) {
    assert.deepEqual(hooks.events(`git -C "${target}" commit -m ok`, 'C:\\start', 'win32'),
      [{ kind: 'コミット', cwd: path.win32.resolve(target) }]);
  }
  assert.deepEqual(hooks.events("& git.exe -C 'C:\\it''s repo' commit -m ok", 'C:\\start', 'win32'),
    [{ kind: 'コミット', cwd: "C:\\it's repo" }]);
});

test('git 外から -C で指定したリポジトリの通知を返し、保存直後は抑制する', t => {
  const f = fixture(t);
  f.git(['commit', '--allow-empty', '-qm', 'recent']);
  const input = { tool_input: { command: `git -C "${f.repo}" commit -m recent` } };
  const result = f.run('context-save-git-trigger', input, f.dir);
  assert.equal(result.status, 0, result.stderr);
  const output = JSON.parse(result.stdout).hookSpecificOutput;
  assert.equal(output.hookEventName, 'PostToolUse');
  assert.ok(output.additionalContext.includes(JSON.stringify(f.repo.replaceAll('\\', '/'))) ||
    output.additionalContext.includes(JSON.stringify(f.repo)));
  f.context(Date.now());
  assert.equal(f.run('context-save-git-trigger', input, f.dir).stdout, '');
});

test('別リポジトリの古い HEAD を参照せず、実際の対象の HEAD を判定する', t => {
  const a = fixture(t), b = fixture(t);
  b.git(['commit', '--allow-empty', '-qm', 'recent']);
  const input = { tool_input: { command: `git -C "${b.repo}" commit -m recent` } };
  const result = a.run('context-save-git-trigger', input);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /additionalContext/);
  assert.equal(a.run('context-save-git-trigger', { tool_input: { command: 'git commit -m old' } }).stdout, '');
});

test('PR の引用文字列はラッパー経由でも無音、実コマンドは通知する', t => {
  const f = fixture(t);
  const run = command => f.run('context-save-git-trigger', { tool_input: { command } });
  assert.equal(run('printf "%s" "; gh pr create --title example"').stdout, '');
  assert.match(run('gh pr create --title example').stdout, /PR 作成/);
});

test('保存前からある日本語・空白・矢印入りパスを削除と誤認しない', t => {
  const f = fixture(t);
  const names = ['日本語.txt', 'space name.txt'];
  if (process.platform !== 'win32') names.push('arrow -> name.txt', 'tab\tquote"line\n.txt');
  for (const name of names) f.write(name, f.saved - 100000);
  assert.equal(hooks.hasChangeSinceSave(f.repo, f.saved), false);
  let result = f.run('context-save-reminder', { session_id: 'session', prompt: '日本語の依頼' });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, '');
  f.write('日本語.txt', f.now);
  result = f.run('context-save-reminder', { session_id: 'session', prompt: '日本語の依頼' });
  assert.match(result.stdout, /保存後の変更があります/);
});

test('rename の移動元と保存ファイルを変更対象に数えない', t => {
  const f = fixture(t);
  f.write('old.txt', f.saved - 100000); f.git(['add', 'old.txt']);
  f.git(['commit', '-qm', 'old file'], { GIT_COMMITTER_DATE: '2020-01-01T00:00:00+00:00' });
  f.git(['mv', 'old.txt', '移動先.txt']);
  f.write('移動先.txt', f.saved - 100000);
  assert.equal(hooks.hasChangeSinceSave(f.repo, f.saved), false);
  f.write('.claude/tasks.md', f.now);
  assert.equal(hooks.hasChangeSinceSave(f.repo, f.saved), false);
  fs.unlinkSync(path.join(f.repo, '移動先.txt'));
  assert.equal(hooks.hasChangeSinceSave(f.repo, f.saved), true);
});

test('新規セッション・再開・context-load 直後は保存通知を抑制する', t => {
  const f = fixture(t);
  f.write('changed.txt', f.now);
  const options = { cwd: f.repo, home: f.home, now: f.now };
  assert.equal(hooks.reminder({ session_id: 'new' }, options), '');
  for (const prompt of ['/context-load', '$context-load', '<command-name>/context-load</command-name>']) {
    f.active();
    assert.equal(hooks.reminder({ session_id: 'session', prompt }, options), '');
    assert.ok(Number(fs.readFileSync(f.marker, 'utf8')) * 1000 >= f.now - 1000);
  }
  f.active();
  fs.utimesSync(f.marker, new Date(f.now - 7200000), new Date(f.now - 7200000));
  assert.equal(hooks.reminder({ session_id: 'session' }, options), '');
});

test('壊れた JSON と context 未作成のリポジトリでは無音', t => {
  const f = fixture(t);
  const result = spawnSync(process.execPath, [path.join(scripts, 'context-save-hooks.js'), 'context-save-reminder'],
    { cwd: f.repo, env: f.env, input: 'not json', encoding: 'utf8' });
  assert.equal(result.status, 0); assert.equal(result.stdout, '');
  fs.unlinkSync(path.join(f.repo, '.claude/context.md'));
  assert.equal(f.run('context-save-git-trigger', { tool_input: { command: 'gh pr create' } }).stdout, '');
});

test('互換入口でも UTF-8 の stdin / stdout を保持する', t => {
  const f = fixture(t);
  const name = 'context-save-git-trigger';
  const input = JSON.stringify({ tool_input: { command: 'gh pr create --title 日本語' } });
  const command = process.platform === 'win32' ? 'powershell.exe' : 'bash';
  const args = process.platform === 'win32'
    ? ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', path.join(scripts, `${name}.ps1`)]
    : [path.join(scripts, `executable_${name}.sh`)];
  const result = spawnSync(command, args, { cwd: f.repo, env: f.env, input, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  const message = JSON.parse(result.stdout).hookSpecificOutput.additionalContext;
  assert.match(message, /PR 作成/);
  assert.match(message, /日本語 repo/);
});
