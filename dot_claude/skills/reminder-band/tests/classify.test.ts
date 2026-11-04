import { expect, test } from 'claude-code/testing'

import { classify, upsert } from '../hooks/classify'
import { AUDIT, DRIFT } from './fixtures'

test('監査リマインダーの実出力を audit と判定する', () => {
  const r = classify(AUDIT)
  expect(r?.kind).toBe('audit')
  expect(r?.summary).toBe('CLAUDE.md 監査 12 日経過')
})

test('ドリフトリマインダーを drift と判定し、件数と先頭のパスを出す', () => {
  const r = classify(DRIFT)
  expect(r?.kind).toBe('drift')
  expect(r?.summary).toBe('chezmoi ドリフト 2 件（MM .claude/docs/work-tips.md ほか）')
})

test('他の注入文は判定しない（素通し）', () => {
  expect(classify('<system-reminder>\n最後の context 保存から 300 分経過\n</system-reminder>')).toBe(undefined)
})

test('同じ種類は上書きし、audit → drift の順に並べる', () => {
  const a1 = classify(AUDIT)!
  const d = classify(DRIFT)!
  const a2 = { ...a1, summary: 'CLAUDE.md 監査 13 日経過' }
  expect(upsert([d, a1], [a2]).map(r => r.summary)).toEqual([a2.summary, d.summary])
})
