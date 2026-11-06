// Linux: node --test tests/context-inject.test.js
// context-inject.sh（SessionStart hook）の出力を、一時ディレクトリの fixture で確かめる。
// ps1 版は CI で動かせないため、同じ fixture を手で流して確認する（.sh が SSOT）。
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');

const script = path.resolve(__dirname, '../dot_claude/scripts/executable_context-inject.sh');

function workspace(t, { git = true } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'context-inject-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const root = path.join(dir, '日本語 ws');
  fs.mkdirSync(path.join(root, '.claude'), { recursive: true });
  const empty = path.join(dir, 'empty'); fs.mkdirSync(empty);
  const config = path.join(dir, 'gitconfig'); fs.writeFileSync(config, '');
  // ロケール未設定の起動経路でも文字単位で数えることを確かめるため、LANG / LC_* を外す。
  const base = Object.fromEntries(Object.entries(process.env).filter(([k]) => !/^(LANG|LC_)/.test(k)));
  const env = { ...base, HOME: dir, GIT_CONFIG_GLOBAL: config, GIT_CONFIG_NOSYSTEM: '1',
    GIT_CEILING_DIRECTORIES: dir,
    GIT_AUTHOR_NAME: 'Test', GIT_COMMITTER_NAME: 'Test',
    GIT_AUTHOR_EMAIL: 'user1@example.com', GIT_COMMITTER_EMAIL: 'user1@example.com' };
  if (git) {
    const run = args => execFileSync('git', ['-C', root, ...args], { env, stdio: 'ignore' });
    run(['init', '-q', '--template=' + empty]);
    run(['commit', '-q', '--allow-empty', '-m', 'init']);
  }
  const write = (name, text) => fs.writeFileSync(path.join(root, '.claude', name), text);
  const inject = (source = 'startup') => {
    const r = spawnSync('bash', [script], { cwd: root, env, input: JSON.stringify({ source }), encoding: 'utf8' });
    assert.equal(r.status, 0, r.stderr);
    return r.stdout;
  };
  return { write, inject };
}

const context = (body = '', updated = '2000-01-01T00:00:00') =>
  `---\nupdated: ${updated}\n---\n\n## 進行中の作業\n- 2026-11-06: 作業A\n\n## 判断メモ\n- 判断B\n${body}`;

const claudeHandoff = `---\nfrom: claude\nat: 2026-11-06T10:00:00\ntopic: 注入の修正\n---\n
## 現状（どこまで動くか）\n- sh は動く\n## 未解決・詰まっている点\n- ps1 の確認が未了\n## 試して駄目だったこと\n- -File 起動\n`;

test('git 変化 → 引き継ぎメモ → Next の順に出し、handoff は要約だけ出す', t => {
  const ws = workspace(t);
  ws.write('context.md', context());
  ws.write('tasks.md', '## Next\n- [ ] 次の作業 @added:2026-11-06\n');
  ws.write('handoff.md', claudeHandoff);
  const out = ws.inject();
  const at = s => out.indexOf(s);
  assert.ok(at('### 保存後の git 変化') > 0);
  assert.ok(at('### 保存後の git 変化') < at('### 引き継ぎメモ（handoff.md）'));
  assert.ok(at('### 引き継ぎメモ（handoff.md）') < at('### 次にやること'));
  assert.match(out, /- 書き手: claude（2026-11-06T10:00:00）／topic: 注入の修正/);
  assert.match(out, /- 未解決:\n {2}- ps1 の確認が未了/);
  assert.doesNotMatch(out, /-File 起動/); // 試して駄目だったことの本文は出さない
});

test('見出し名が仕様と違う handoff（未確認・制約）も未解決として拾う', t => {
  const ws = workspace(t);
  ws.write('context.md', context());
  ws.write('handoff.md', '---\nfrom: codex\nat: 2026-11-02T09:00:00\ntopic: 調査\n---\n\n## 現状\n- 途中\n## 未確認・制約\n- API の上限が不明\n## 再現手順\n- なし\n');
  assert.match(ws.inject(), /- 未解決:\n {2}- API の上限が不明/);
});

test('未解決が なし だけなら「未解決: なし」と出す', t => {
  const ws = workspace(t);
  ws.write('context.md', context());
  ws.write('handoff.md', claudeHandoff.replace('- ps1 の確認が未了', '- なし'));
  assert.match(ws.inject(), /- 未解決: なし/);
});

test('上限を超えても git 変化と引き継ぎメモは残り、文字単位で打ち切る', t => {
  const ws = workspace(t);
  ws.write('context.md', context(Array.from({ length: 400 }, (_, i) => `- 判断 ${i} あいうえお🙂かきくけこ`).join('\n')));
  ws.write('handoff.md', claudeHandoff);
  const out = ws.inject();
  const [body, note] = out.split('\n…（');
  assert.equal([...body].length, 5800); // bash はコードポイント単位で数える（JS の length は UTF-16 単位）
  assert.match(note, /^5800 字で打ち切り/);
  assert.ok(!out.includes('�'));
  assert.match(out, /### 保存後の git 変化/);
  assert.match(out, /### 引き継ぎメモ（handoff.md）/);
});

test('CRLF・BOM 付きの context.md / tasks.md も読める', t => {
  const ws = workspace(t);
  ws.write('context.md', '﻿' + context('', '2026-11-06T08:00:00').replace(/\n/g, '\r\n'));
  ws.write('tasks.md', '## Next\r\n- [ ] CRLF の作業\r\n');
  const out = ws.inject();
  assert.match(out, /最終保存: 2026-11-06T08:00:00）/);
  assert.match(out, /### 次にやること（tasks.md の Next）\n- \[ \] CRLF の作業/);
  assert.match(out, /### 進行中の作業\n- 2026-11-06: 作業A/);
  assert.ok(!out.includes('\r'));
});

test('git 外では CWD の .claude/ を読み、git 変化は「git 管理外」と出す', t => {
  const ws = workspace(t, { git: false });
  ws.write('context.md', context());
  ws.write('tasks.md', '## Next\n- [ ] ホームの作業\n');
  const out = ws.inject();
  assert.match(out, /### 保存後の git 変化\n- git 管理外/);
  assert.match(out, /- \[ \] ホームの作業/);
});

test('frontmatter が無ければ、本文の --- 区切りの updated を拾わない', t => {
  const ws = workspace(t);
  ws.write('context.md', '# 見出し\n\n---\nupdated: 2020-01-01T00:00:00\n---\n\n## 進行中の作業\n- 2026-11-06: 作業A\n');
  assert.match(ws.inject(), /最終保存: 不明）/);
});

test('引用符付きの updated は引用符を外して表示する', t => {
  const ws = workspace(t);
  ws.write('context.md', context('', '"2026-11-06T08:00:00"'));
  assert.match(ws.inject(), /最終保存: 2026-11-06T08:00:00）/);
});

test('compact では再注入の見出しを出す', t => {
  const ws = workspace(t);
  ws.write('context.md', context());
  assert.match(ws.inject('compact'), /^## compact 後の再注入/);
});
