#!/usr/bin/env node
/**
 * Codex `adversarial-review --json` の出力を codex-review-loop が使う形へ要約する。
 *
 * 入力の payload 形状（codex プラグイン v1.0.6 `codex-companion.mjs` の adversarial 経路）:
 *   { review, target, threadId, context, codex:{status,...}, result, rawOutput, parseError, reasoningSummary }
 *   `result` は schemas/review-output.schema.json 準拠（verdict / summary / findings[] / next_steps[]）。
 *   findings[].severity は critical | high | medium | low、confidence は 0-1。
 *
 * 使い方:
 *   node summarize-review.mjs <current.json> [previous.json]
 *
 * @param current.json  今ラウンドの `adversarial-review --json` 出力ファイル
 * @param previous.json 前ラウンドの同ファイル（省略可）。無進捗検知に使う
 *
 * 標準出力（JSON）:
 *   成功時 { ok: true, verdict, summary, counts:{critical,high,medium,low}, blocking[], other[], repeated[] }
 *     blocking = severity が critical / high の finding（`key` 付き。修正対象はこれだけ）
 *     other    = medium / low の finding（報告のみ、修正対象外）
 *     repeated = previous 側にも blocking として同じ key があったもの（無進捗検知用）
 *   失敗時 { ok: false, reason, parseError?, rawOutput?, codexStatus? }
 *
 * 終了コード: 0 = 要約成功 / 1 = 入力不正・Codex 側の失敗・構造化出力の取得失敗
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

function readPayload(filePath) {
  const raw = fs.readFileSync(filePath, "utf8").trim();
  if (!raw) {
    throw new Error(`${filePath} が空です（Codex の実行が失敗した可能性があります）`);
  }
  return JSON.parse(raw);
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

function blockingKeysOf(payload) {
  const findings = payload?.result?.findings;
  if (!Array.isArray(findings)) {
    return new Set();
  }
  return new Set(findings.filter((f) => BLOCKING_SEVERITIES.has(f?.severity)).map(findingKey));
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

  let payload;
  try {
    payload = readPayload(currentPath);
  } catch (error) {
    fail(`current.json を読めませんでした: ${error.message}`);
  }

  if (!payload?.result) {
    fail("構造化レビュー結果が取得できませんでした", {
      parseError: payload?.parseError ?? null,
      rawOutput: payload?.rawOutput ?? null,
      codexStatus: payload?.codex?.status ?? null
    });
  }

  const findings = Array.isArray(payload.result.findings) ? payload.result.findings : [];
  const counts = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const finding of findings) {
    if (Object.prototype.hasOwnProperty.call(counts, finding?.severity)) {
      counts[finding.severity] += 1;
    }
  }

  let previousBlockingKeys = new Set();
  if (previousPath) {
    try {
      previousBlockingKeys = blockingKeysOf(readPayload(previousPath));
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
        verdict: payload.result.verdict,
        summary: payload.result.summary,
        target: payload.target?.label ?? null,
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
        nextSteps: Array.isArray(payload.result.next_steps) ? payload.result.next_steps : []
      },
      null,
      2
    )
  );
}

main();
