#!/usr/bin/env -S npx tsx
/**
 * expand-shared-css.ts — SSOT 共通 CSS を各 HTML 補足ページへインライン展開 / 検証する。
 *
 * spec-writer スキルの「HTML 補足の CSS = SSOT + 生成時インライン展開型」方針
 * (references/html-css-centralization.md) を機械化するためのプロジェクト常駐ヘルパ。
 * LLM の手転記に依存すると「全文コピー漏れ」「相対パスズレ」「再展開忘れ」が起きるため、
 * 展開と drift 検査をこのスクリプトに寄せて MUST レベルで強制できるようにする。
 *
 * このファイルはスキル側に置く「雛形」。各リポジトリへコピーして使う想定
 * (配置先は例: `scripts/expand-shared-css.ts` / `tools/expand-shared-css.ts`)。
 *
 * 前提:
 *   - SSOT は 1 ファイル (既定 `docs/_html/_shared/spec-page.css`)。
 *   - 各 HTML は <style data-shared-source="<SSOT への相対パス>"> ... </style> ブロックを 1 つ持つ。
 *     このブロックの中身を SSOT 全文で置換する (属性値の相対パスは各 HTML 基準で自動算出)。
 *   - 対象 HTML は SSOT への相対パスを data-shared-source 属性に持つことで機械的に発見される。
 *
 * 使い方 (tsx 実行例):
 *   npx tsx scripts/expand-shared-css.ts            # 展開 (全対象 HTML を SSOT 最新で上書き)
 *   npx tsx scripts/expand-shared-css.ts --check    # 検証のみ (drift があれば非ゼロ終了。CI / pre-commit 向け)
 *   npx tsx scripts/expand-shared-css.ts --ssot docs/_html/_shared/spec-page.css --root docs
 *
 * 終了コード: 0 = 成功 / drift なし、1 = drift あり (--check) または展開失敗、2 = 引数・前提エラー。
 *
 * 依存: Node.js 標準ライブラリのみ (tsx / ts-node で実行)。外部 npm 不要。
 */

import { readFileSync, writeFileSync, readdirSync, statSync } from "node:fs";
import { join, relative, dirname, resolve, posix, sep } from "node:path";

interface Options {
  ssotPath: string;
  rootDir: string;
  check: boolean;
}

/** data-shared-source 属性を持つ <style> ブロックの開始タグと中身を捉える。
 *  属性内に `>` は来ない前提 (相対パスのみ) なので `[^>]*` で十分。 */
const STYLE_BLOCK_RE =
  /(<style\b[^>]*\bdata-shared-source\s*=\s*["'][^"']*["'][^>]*>)([\s\S]*?)(<\/style>)/i;

function parseArgs(argv: string[]): Options {
  const opts: Options = {
    ssotPath: "docs/_html/_shared/spec-page.css",
    rootDir: "docs",
    check: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--check") opts.check = true;
    else if (arg === "--ssot") opts.ssotPath = requireValue(argv, ++i, "--ssot");
    else if (arg === "--root") opts.rootDir = requireValue(argv, ++i, "--root");
    else {
      console.error(`未知の引数: ${arg}`);
      process.exit(2);
    }
  }
  return opts;
}

function requireValue(argv: string[], i: number, flag: string): string {
  const v = argv[i];
  if (v === undefined) {
    console.error(`${flag} には値が必要です`);
    process.exit(2);
  }
  return v;
}

/** rootDir 以下を再帰走査して .html ファイルの絶対パスを集める。 */
function findHtmlFiles(rootDir: string): string[] {
  const out: string[] = [];
  const walk = (dir: string): void => {
    for (const entry of readdirSync(dir)) {
      const full = join(dir, entry);
      if (statSync(full).isDirectory()) walk(full);
      else if (entry.toLowerCase().endsWith(".html")) out.push(full);
    }
  };
  walk(resolve(rootDir));
  return out;
}

/** SSOT への相対パスを HTML ファイル基準で算出し、POSIX 区切り (/) に正規化する。
 *  Windows 実行でも HTML 属性値は `/` 区切りに揃える。 */
function relativeSsotPath(htmlFile: string, ssotAbs: string): string {
  const rel = relative(dirname(htmlFile), ssotAbs);
  return rel.split(sep).join(posix.sep);
}

/** 1 HTML に対し SSOT を展開した結果文字列を返す。展開対象でなければ null。 */
function buildExpanded(
  html: string,
  htmlFile: string,
  ssotContent: string,
  ssotAbs: string,
): string | null {
  const match = STYLE_BLOCK_RE.exec(html);
  if (!match) return null;
  const openTag = match[1];
  const closeTag = match[3];

  // data-shared-source 属性値を「各 HTML 基準の正しい相対パス」へ更新する
  const correctRel = relativeSsotPath(htmlFile, ssotAbs);
  const fixedOpenTag = openTag.replace(
    /(\bdata-shared-source\s*=\s*["'])[^"']*(["'])/i,
    `$1${correctRel}$2`,
  );

  const header =
    `\n    /* ===== 共通 CSS（SSOT: ${correctRel} の生成時コピー・直接編集禁止） =====\n` +
    `     * このブロックは expand-shared-css.ts が自動生成する。手で編集しない。\n` +
    `     * スタイル変更は SSOT 側で行い、本スクリプトで再展開する。 */\n`;
  const body = `${header}${ssotContent.trimEnd()}\n  `;

  return html.replace(STYLE_BLOCK_RE, `${fixedOpenTag}${body}${closeTag}`);
}

/** 改行コード差・末尾空白を吸収して比較するための正規化。 */
function normalize(s: string): string {
  return s.replace(/\r\n/g, "\n").trimEnd();
}

function main(): void {
  const opts = parseArgs(process.argv.slice(2));
  const ssotAbs = resolve(opts.ssotPath);

  let ssotContent: string;
  try {
    ssotContent = readFileSync(ssotAbs, "utf8");
  } catch {
    console.error(`SSOT が読めません: ${opts.ssotPath}`);
    process.exit(2);
  }

  const htmlFiles = findHtmlFiles(opts.rootDir).filter((f) =>
    /\bdata-shared-source\b/.test(readFileSync(f, "utf8")),
  );

  if (htmlFiles.length === 0) {
    console.error(
      `data-shared-source を持つ HTML が ${opts.rootDir} 以下に見つかりません`,
    );
    process.exit(2);
  }

  let drifted = 0;
  let updated = 0;

  for (const file of htmlFiles) {
    const original = readFileSync(file, "utf8");
    const expanded = buildExpanded(original, file, ssotContent, ssotAbs);
    const rel = relative(process.cwd(), file);

    if (expanded === null) {
      console.error(`  SKIP (style ブロック検出失敗): ${rel}`);
      continue;
    }

    if (normalize(expanded) === normalize(original)) continue; // 一致 = drift なし

    if (opts.check) {
      drifted++;
      console.error(`  DRIFT: ${rel} — SSOT と不一致 (再展開が必要)`);
    } else {
      writeFileSync(file, expanded, "utf8");
      updated++;
      console.log(`  展開: ${rel}`);
    }
  }

  if (opts.check) {
    if (drifted > 0) {
      console.error(
        `\n${drifted} 件が SSOT と drift しています。展開を実行してください: npx tsx ${relative(process.cwd(), process.argv[1])}`,
      );
      process.exit(1);
    }
    console.log(`全 ${htmlFiles.length} 件が SSOT と一致 (drift なし)`);
  } else {
    console.log(
      `\n展開完了: ${updated} 件更新 / ${htmlFiles.length} 件中 (差分なしはスキップ)`,
    );
  }
}

main();
