#!/usr/bin/env node
/**
 * `codex exec --output-schema ... -o <FILE>` が書いたレビュー結果を、codex-review-loop が使う形へ要約する。
 *
 * 入力の形状: `schemas/review-output.schema.json` 準拠のオブジェクトが**素で**書かれている。
 *   { verdict, summary, findings[], next_steps[] }
 *   findings[].severity は critical | high | medium | low、confidence は 0-1。
 *
 * 注意: `codex exec` は中間ターンでも同じ形状の JSON を stdout に出すが、そちらは findings が空のことがある。
 * 必ず `-o` で書かせた最終メッセージのファイルを渡すこと（stdout を拾うと空結果を掴む）。
 *
 * 使い方:
 *   node summarize-review.mjs <current.json> [previous.json]
 *
 * @param current.json  今ラウンドの `-o` 出力ファイル
 * @param previous.json 前ラウンドの同ファイル（省略可）。無進捗検知に使う
 *
 * 標準出力（JSON）:
 *   成功時 { ok: true, verdict, summary, counts:{critical,high,medium,low}, blocking[], other[], repeated[], nextSteps[] }
 *     blocking = severity が critical / high の finding（`key` 付き。修正対象はこれだけ）
 *     other    = medium / low の finding（報告のみ、修正対象外）
 *     repeated = previous 側にも blocking として同じ key があったもの（無進捗検知用）
 *   失敗時 { ok: false, reason, rawOutput? }
 *
 * 終了コード: 0 = 要約成功 / 1 = 入力不正・構造化出力の取得失敗
 */

import fs from "node:fs";

const BLOCKING_SEVERITIES = new Set(["critical", "high"]);

/**
 * finding の同一性判定キーを作る。
 * ラウンド間で本文や行番号は揺れるため、ファイルと正規化したタイトルだけで突き合わせる。
 *
 * @param {{file?: string, title?: string}} finding
 * @returns {string} `<file>::<正規化タイトル>`
 */
function findingKey(finding) {
  const file = String(finding?.file ?? "unknown").trim();
  const title = String(finding?.title ?? "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
  return `${file}::${title}`;
}

/**
 * レビュー結果ファイルを読む。スキーマ準拠オブジェクトでなければ null を返す。
 *
 * @param {string} filePath
 * @returns {{raw: string, data: object|null}}
 */
function readResult(filePath) {
  const raw = fs.readFileSync(filePath, "utf8").trim();
  if (!raw) {
    throw new Error(`${filePath} が空です（codex exec が最終メッセージを書けていない可能性があります）`);
  }
  let data = null;
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed) && Array.isArray(parsed.findings)) {
      data = parsed;
    }
  } catch {
    data = null;
  }
  return { raw, data };
}

function toFinding(finding) {
  return {
    key: findingKey(finding),
    severity: finding.severity,
    title: finding.title,
    file: finding.file,
    line: `${finding.line_start}-${finding.line_end}`,
    confidence: finding.confidence,
    body: finding.body,
    recommendation: finding.recommendation
  };
}

function blockingKeysOf(data) {
  if (!Array.isArray(data?.findings)) {
    return new Set();
  }
  return new Set(data.findings.filter((f) => BLOCKING_SEVERITIES.has(f?.severity)).map(findingKey));
}

function fail(reason, extra = {}) {
  console.log(JSON.stringify({ ok: false, reason, ...extra }, null, 2));
  process.exit(1);
}

function main() {
  const [currentPath, previousPath] = process.argv.slice(2);
  if (!currentPath) {
    fail("使い方: node summarize-review.mjs <current.json> [previous.json]");
  }

  let current;
  try {
    current = readResult(currentPath);
  } catch (error) {
    fail(`current.json を読めませんでした: ${error.message}`);
  }

  if (!current.data) {
    fail("スキーマ準拠のレビュー結果として解釈できませんでした", {
      rawOutput: current.raw.slice(0, 4000)
    });
  }

  const findings = current.data.findings;
  const counts = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const finding of findings) {
    if (Object.prototype.hasOwnProperty.call(counts, finding?.severity)) {
      counts[finding.severity] += 1;
    }
  }

  let previousBlockingKeys = new Set();
  if (previousPath) {
    try {
      previousBlockingKeys = blockingKeysOf(readResult(previousPath).data);
    } catch {
      // 前ラウンドのファイルが読めない場合は無進捗検知だけ諦める（今ラウンドの要約は返す）
      previousBlockingKeys = new Set();
    }
  }

  const blocking = findings.filter((f) => BLOCKING_SEVERITIES.has(f?.severity)).map(toFinding);

  console.log(
    JSON.stringify(
      {
        ok: true,
        verdict: current.data.verdict ?? null,
        summary: current.data.summary ?? "",
        counts,
        blocking,
        other: findings
          .filter((f) => !BLOCKING_SEVERITIES.has(f?.severity))
          .map((f) => ({
            severity: f.severity,
            title: f.title,
            file: f.file,
            line: `${f.line_start}-${f.line_end}`
          })),
        repeated: blocking.filter((f) => previousBlockingKeys.has(f.key)).map((f) => f.key),
        nextSteps: Array.isArray(current.data.next_steps) ? current.data.next_steps : []
      },
      null,
      2
    )
  );
}

main();
