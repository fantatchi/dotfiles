#!/usr/bin/env node
/**
 * migrate-tasks.mjs — 捕捉箱に残っているプロジェクトタスクを、各プロジェクトの作業キューへ移す。
 *
 * 2026-07-27 のタスクストア分離（捕捉箱 = Obsidian / 作業キュー = <project>/.claude/tasks.md）に伴う
 * 一度きりの移行ツール。**この PC に実在するリポジトリの分だけ**を引き取り、見つからないプロジェクトの
 * 行は捕捉箱に残す（別 PC でこのスクリプトを実行したときに、その PC 側が引き取る）。
 *
 * 使い方:
 *   node ~/.claude/scripts/migrate-tasks.mjs            # dry-run（既定・書き込みなし）
 *   node ~/.claude/scripts/migrate-tasks.mjs --apply    # 実際に書き込む
 *
 * 実行前に **Obsidian を完全終了** すること（タスクトレイから Quit）。開いたままだと Obsidian Sync が
 * 外部編集を巻き戻す（実例あり）。
 *
 * 冪等: 移行済みの行は捕捉箱から消えるため再実行しても何も起きない。作業キュー側も同一タイトルの
 * 行があれば追加しない。
 *
 * リポジトリ探索はホーム直下 + そのシンボリックリンク先（WSL の `~/win-work` → `C:\...` 等）を深さ 3 まで。
 * Windows ファイルシステムを含むと 5 分程度かかることがある。`MIGRATE_TASK_ROOTS=/path/a:/path/b` で
 * 起点を絞ると速い。
 *
 * 移行が全 PC で完了したらこのスクリプトは削除してよい。
 */

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const HOME = os.homedir();
const APPLY = process.argv.includes('--apply');
const VAULT_TASKS = process.env.CAPTURE_STORE || path.join(HOME, 'ObsidianVault', '00_meta', 'tasks.md');
const SCAN_DEPTH = 3;
const SKIP_DIRS = new Set([
  'node_modules', '.git', '.cache', '.npm', '.nvm', '.local', '.rustup', '.cargo',
  'ObsidianVault', '.vscode-server', '.vscode-server-insiders', 'AppData', '.venv',
  'venv', '__pycache__', 'snap', '.pyenv', '.volta', 'go', 'dist', 'build', '.next',
]);
const SECTIONS = ['Next', 'Someday'];

const QUEUE_TEMPLATE = (name) => `# Tasks — ${name}

このファイルは \`/context-save\` が管理します。
手で \`[x]\` を付ける・行を足すのは OK（次回保存時に正規化されます）。

## Next

## Someday

## Done
`;

/** 捕捉箱を読み、セクションごとの行配列に分解する。 */
function parseStore(text) {
  const lines = text.split('\n');
  const sections = new Map();
  let current = null;
  lines.forEach((line, index) => {
    const heading = line.match(/^##\s+(\S+)/);
    if (heading) {
      current = heading[1];
      sections.set(current, []);
      return;
    }
    if (current && /^\s*-\s+\[[ xX]\]/.test(line)) {
      sections.get(current).push({ index, line });
    }
  });
  return { lines, sections };
}

/**
 * 走査の起点。ホーム直下のシンボリックリンク（WSL の `~/win-work` → `/mnt/c/...` 等）も辿るため、
 * 実体パスに解決して起点に加える。`MIGRATE_TASK_ROOTS`（`:` 区切り）で明示指定も可。
 */
function scanRoots() {
  if (process.env.MIGRATE_TASK_ROOTS) {
    return process.env.MIGRATE_TASK_ROOTS.split(':').filter(Boolean);
  }
  const roots = [HOME];
  for (const entry of fs.readdirSync(HOME, { withFileTypes: true })) {
    if (!entry.isSymbolicLink() || SKIP_DIRS.has(entry.name)) continue;
    try {
      const real = fs.realpathSync(path.join(HOME, entry.name));
      if (fs.statSync(real).isDirectory()) roots.push(real);
    } catch { /* 壊れたリンクは無視 */ }
  }
  return roots;
}

/** 起点配下を深さ制限つきに走査し、リポジトリ名 → パスの対応を作る（シンボリックリンクも辿る）。 */
function scanRepos(root, depth, found, visited) {
  if (depth < 0) return found;
  let real;
  try {
    real = fs.realpathSync(root);
  } catch {
    return found;
  }
  if (visited.has(real)) return found;
  visited.add(real);

  let entries;
  try {
    entries = fs.readdirSync(root, { withFileTypes: true });
  } catch {
    return found;
  }
  for (const entry of entries) {
    if (SKIP_DIRS.has(entry.name)) continue;
    const dir = path.join(root, entry.name);
    let isDir;
    try {
      isDir = fs.statSync(dir).isDirectory(); // シンボリックリンクの先を見る
    } catch {
      continue;
    }
    if (!isDir) continue;
    if (fs.existsSync(path.join(dir, '.git')) && !found.has(entry.name)) {
      found.set(entry.name, dir);
    }
    scanRepos(dir, depth - 1, found, visited);
  }
  return found;
}

/** 作業キューの指定セクションへ行を追記した内容を返す（重複はスキップ）。 */
function addToQueue(queueText, section, titles) {
  const lines = queueText.split('\n');
  const headingIndex = lines.findIndex((l) => l.trim() === `## ${section}`);
  if (headingIndex === -1) throw new Error(`セクション "## ${section}" が見つかりません`);

  let end = headingIndex + 1;
  while (end < lines.length && !/^##\s/.test(lines[end])) end += 1;

  const existing = lines.slice(headingIndex, end).join('\n');
  const fresh = titles.filter((t) => !existing.includes(t));
  if (fresh.length === 0) return { text: queueText, added: 0 };

  let insertAt = end;
  while (insertAt > headingIndex + 1 && lines[insertAt - 1].trim() === '') insertAt -= 1;

  const block = fresh.map((t) => `- [ ] ${t}`);
  lines.splice(insertAt, 0, ...block);
  return { text: lines.join('\n'), added: fresh.length };
}

function main() {
  if (!fs.existsSync(VAULT_TASKS)) {
    console.error(`捕捉箱が見つかりません: ${VAULT_TASKS}`);
    process.exit(1);
  }

  console.log(APPLY
    ? '⚠️  --apply モード: 実際に書き込みます。Obsidian を終了してから実行してください。\n'
    : 'dry-run モード（書き込みません）。実行するには --apply を付けてください。\n');

  const original = fs.readFileSync(VAULT_TASKS, 'utf8');
  const { lines, sections } = parseStore(original);

  // プロジェクトタグ付きの行を集める
  const byProject = new Map(); // name -> { Next: [{index,title}], Someday: [...] }
  for (const section of SECTIONS) {
    for (const { index, line } of sections.get(section) || []) {
      const tag = line.match(/#project\/([A-Za-z0-9._-]+)/);
      if (!tag) continue;
      const name = tag[1];
      const title = line
        .replace(/^\s*-\s+\[[ xX]\]\s*/, '')
        .replace(`#project/${name}`, '')
        .replace(/\s{2,}/g, ' ')
        .trim();
      if (!byProject.has(name)) byProject.set(name, { Next: [], Someday: [] });
      byProject.get(name)[section].push({ index, title });
    }
  }

  if (byProject.size === 0) {
    console.log('移行対象はありません（捕捉箱にプロジェクトタグ付きの Next / Someday なし）。');
    return;
  }

  const repos = new Map();
  const visited = new Set();
  for (const root of scanRoots()) scanRepos(root, SCAN_DEPTH, repos, visited);
  const removeIndexes = new Set();
  const migrated = [];
  const skipped = [];

  for (const [name, buckets] of [...byProject].sort()) {
    const root = name === 'global' ? HOME : repos.get(name);
    const total = buckets.Next.length + buckets.Someday.length;
    if (!root) {
      skipped.push({ name, total });
      continue;
    }

    const queuePath = path.join(root, '.claude', 'tasks.md');
    let queueText = fs.existsSync(queuePath)
      ? fs.readFileSync(queuePath, 'utf8')
      : QUEUE_TEMPLATE(name === 'global' ? 'home workspace' : name);

    let added = 0;
    for (const section of SECTIONS) {
      const titles = buckets[section].map((t) => t.title);
      if (titles.length === 0) continue;
      const result = addToQueue(queueText, section, titles);
      queueText = result.text;
      added += result.added;
      buckets[section].forEach((t) => removeIndexes.add(t.index));
    }

    if (APPLY && added > 0) {
      fs.mkdirSync(path.dirname(queuePath), { recursive: true });
      fs.writeFileSync(queuePath, queueText, 'utf8');
    }
    migrated.push({ name, added, total, queuePath });
  }

  // 捕捉箱から移行済み行を削除
  if (removeIndexes.size > 0 && APPLY) {
    const backup = `${VAULT_TASKS}.bak.${new Date().toISOString().replace(/[:.]/g, '').slice(0, 15)}`;
    fs.writeFileSync(backup, original, 'utf8');
    const kept = lines.filter((_, i) => !removeIndexes.has(i));
    fs.writeFileSync(VAULT_TASKS, kept.join('\n'), 'utf8');
    console.log(`捕捉箱をバックアップしました: ${backup}\n`);
  }

  console.log('== 移行 ==');
  for (const m of migrated) {
    console.log(`  ${m.name.padEnd(24)} ${String(m.added).padStart(2)} 件 → ${m.queuePath.replace(HOME, '~')}`);
  }
  if (skipped.length > 0) {
    console.log('\n== この PC に無いため捕捉箱に残したもの（別 PC で実行してください） ==');
    for (const s of skipped) console.log(`  ${s.name.padEnd(24)} ${String(s.total).padStart(2)} 件`);
  }
  console.log(`\n合計: 移行 ${migrated.reduce((a, m) => a + m.added, 0)} 件 / 残置 ${skipped.reduce((a, s) => a + s.total, 0)} 件`);
  if (!APPLY) console.log('\n（dry-run のため何も書き込んでいません）');
}

main();
