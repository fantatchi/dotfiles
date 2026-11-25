// Linux / Windows: node --test tests/gtd-digest-hook.test.js
// gtd-digest-hook.js の digest()（純関数）を確かめる。run() は実ファイルと状態ファイルに触るので呼ばない。
const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');

const { promote, digest } = require(path.resolve(__dirname, '../dot_claude/scripts/gtd-digest-hook.js'));

const now = new Date(2026, 10, 6, 9, 0, 0); // 2026-11-06（ローカル時刻）

const store = [
  '# Tasks',
  '',
  '## Inbox',
  '<!-- inbox-anchor -->',
  '- [x] #project/global チェック済み @captured-on-mobile  ',
  '- [ ] #project/global 新しい捕捉 @captured-on-mobile @added:2026-11-04',
  '',
  '## Next',
  '- [ ] 古い次の作業 @added:2026-09-01',
  '- [ ] 新しい次の作業 @added:2026-11-01',
  '',
  '## Waiting',
  '- [ ] 古い待ち @added:2026-09-01',
  '',
  '## Someday',
  '- [ ] 古いいつか A @added:2026-09-01',
  '- [ ] 古いいつか B @added:2026-09-01',
  '- [x] いつかで済んだもの',
  '',
  '## Done',
  '- [x] 2026-11-05 済み',
].join('\n');

test('古いタスクの件数に Someday を数えない（Next と Waiting は数える）', () => {
  assert.match(digest(store, now), /⏳ 登録から 30 日を超えたタスクが 2 件あります/);
});

test('昇格を見送ったときのチェック済みは Done 以外の全セクション（Someday を含む）で数える', () => {
  assert.match(digest(store, now), /チェック済みが 2 件残っています/);
});

// ---- promote（チェック済みの Done 昇格）----

const today = '2026-11-06';

test('Done 以外の全セクションの [x] を Done の先頭へ移し、日付を付けて印を外す', () => {
  const { text, count } = promote(store, today);
  assert.equal(count, 2);
  const lines = text.split('\n');
  const done = lines.indexOf('## Done');
  assert.deepEqual(lines.slice(done + 1), [
    '- [x] 2026-11-06 #project/global チェック済み',
    '- [x] 2026-11-06 いつかで済んだもの',
    '- [x] 2026-11-05 済み',
  ]);
  assert.ok(!lines.slice(0, done).some(l => /^- \[x\]/i.test(l.trim())));
});

test('日付が既にある行はそのまま（日付を重ねない）、大文字の [X] と字下げも拾う', () => {
  const src = ['## Inbox', '  - [X] 2026-11-01 前に完了 @added:2026-10-01', '', '## Done', ''].join('\n');
  const { text, count } = promote(src, today);
  assert.equal(count, 1);
  assert.match(text, /^- \[x\] 2026-11-01 前に完了$/m);
});

test('inbox-anchor は動かさない', () => {
  const { text } = promote(store, today);
  assert.match(text, /## Inbox\n<!-- inbox-anchor -->\n- \[ \] #project\/global 新しい捕捉/);
});

test('Done の見出しの後に空行があれば、空行は残してその下へ入れる', () => {
  const src = ['## Next', '- [x] 済んだ', '', '## Done', '', '- [x] 2026-11-05 前の分', ''].join('\n');
  const { text } = promote(src, today);
  assert.equal(text, ['## Next', '', '## Done', '', '- [x] 2026-11-06 済んだ', '- [x] 2026-11-05 前の分', ''].join('\n'));
});

test('Done が無ければ末尾に作る', () => {
  const src = ['## Inbox', '- [x] 済んだ', '- [ ] まだ', ''].join('\n');
  const { text } = promote(src, today);
  assert.equal(text, ['## Inbox', '- [ ] まだ', '', '## Done', '', '- [x] 2026-11-06 済んだ', ''].join('\n'));
});

test('見出しが二重（Sync 競合の疑い）なら何も変えない', () => {
  const src = ['## Inbox', '- [x] 済んだ', '## Inbox', '## Done', ''].join('\n');
  assert.deepEqual(promote(src, today), { text: src, count: 0 });
});

test('移すものが無ければ元の文字列のまま（2 回かけても同じ）', () => {
  const once = promote(store, today).text;
  assert.deepEqual(promote(once, today), { text: once, count: 0 });
});

test('CRLF のファイルは CRLF のまま書く', () => {
  const { text } = promote(store.replace(/\n/g, '\r\n'), today);
  assert.ok(!/[^\r]\n/.test(text));
  assert.match(text, /## Done\r\n- \[x\] 2026-11-06 #project\/global チェック済み\r\n/);
});

// ---- digest の昇格・剪定の知らせ ----

test('移した件数を知らせ、残りが無ければ「残っています」は出さない', () => {
  const msg = digest(promote(store, today).text, now, 2);
  assert.match(msg, /✅ チェック済みの 2 件を Done へ移しました/);
  assert.doesNotMatch(msg, /残っています/);
});

test('Done の完了日が 30 日より前の行を剪定の候補として数える', () => {
  const src = store.replace('- [x] 2026-11-05 済み', '- [x] 2026-11-05 済み\n- [x] 2026-10-06 ちょうど 31 日前\n- [x] 2026-10-07 ちょうど 30 日前');
  assert.match(digest(src, now), /🧹 Done に 30 日を超えた完了が 1 件あります（\/gtd-list で剪定）/);
  assert.doesNotMatch(digest(store, now), /🧹/);
});

test('Inbox と Next が空でも、昇格や剪定の知らせがあれば表示する', () => {
  const empty = ['## Inbox', '', '## Next', '', '## Done', '- [x] 2026-09-01 古い完了'].join('\n');
  assert.match(digest(empty, now), /🧹/);
  assert.match(digest(['## Inbox', '', '## Next', ''].join('\n'), now, 1), /✅/);
  assert.equal(digest(['## Inbox', '', '## Next', ''].join('\n'), now), '');
});

test('Someday だけが古いときは古いタスクの行を出さない', () => {
  const onlySomeday = store
    .replace('- [ ] 古い次の作業 @added:2026-09-01', '- [ ] 次の作業 @added:2026-11-01')
    .replace('- [ ] 古い待ち @added:2026-09-01', '');
  assert.doesNotMatch(digest(onlySomeday, now), /⏳/);
});
