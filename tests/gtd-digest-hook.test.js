// Linux / Windows: node --test tests/gtd-digest-hook.test.js
// gtd-digest-hook.js の digest()（純関数）を確かめる。run() は実ファイルと状態ファイルに触るので呼ばない。
const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');

const { digest } = require(path.resolve(__dirname, '../dot_claude/scripts/gtd-digest-hook.js'));

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

test('チェック済みは Done 以外の全セクション（Someday を含む）で数える', () => {
  assert.match(digest(store, now), /チェック済みが 2 件あります/);
});

test('Someday だけが古いときは古いタスクの行を出さない', () => {
  const onlySomeday = store
    .replace('- [ ] 古い次の作業 @added:2026-09-01', '- [ ] 次の作業 @added:2026-11-01')
    .replace('- [ ] 古い待ち @added:2026-09-01', '');
  assert.doesNotMatch(digest(onlySomeday, now), /⏳/);
});
