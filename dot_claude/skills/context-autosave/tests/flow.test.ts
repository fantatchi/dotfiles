import { expect, test } from 'claude-code/testing'

import { REMINDER_MARK } from '../hooks/logic'

const turn = (extra: object = {}) => ({ answer: 'ok', durationMs: 1, isAborted: false, turnId: 't1', reason: 'answer', ...extra }) as never
const settle = () => new Promise(r => setTimeout(r, 20))

const REMINDER = `<system-reminder>\n${REMINDER_MARK} 300 分経過し、保存後の変更があります\n</system-reminder>`

test('保存リマインダーは Claude に渡さず、ターンの後で context-save を実行する', async ($, on) => {
  const runs: string[] = []
  const toasts: string[] = []
  let injected = ['other', REMINDER]
  on('classic.UserPromptSubmit', () => ({ additionalContext: injected }))
  on('command.run', (_, e) => {
    runs.push(e.command)
    return { text: '' }
  })
  on('ui.toast', (_, e) => {
    toasts.push(String((e as { text?: string }).text ?? ''))
    return { value: undefined }
  })
  on('turn.complete', () => ({ text: 'done' }))

  const r = await $.classic.UserPromptSubmit({ prompt: 'hi' } as never)
  expect(r.additionalContext).toEqual(['other'])
  expect(runs).toEqual([])

  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual(['context-save'])

  // 依頼した /context-save の送信でもリマインダーが再注入されるが、保存のターンの後に 2 回目は走らない
  await $.classic.UserPromptSubmit({ prompt: '/context-save' } as never)
  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual(['context-save'])
  // 保存が終わった後の通常のターンでも、新たなリマインダーが無ければ走らない
  injected = ['other']
  await $.classic.UserPromptSubmit({ prompt: 'next' } as never)
  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual(['context-save'])
})

test('サブエージェントのターン終了では実行しない', async ($, on) => {
  const runs: string[] = []
  on('classic.UserPromptSubmit', () => ({ additionalContext: [REMINDER] }))
  on('command.run', (_, e) => (runs.push(e.command), { text: '' }))
  on('ui.toast', () => ({ value: undefined }))
  on('turn.complete', () => ({ text: '' }))
  await $.classic.UserPromptSubmit({ prompt: 'hi' } as never)
  await $.turn.complete(turn({ agentId: 'a1' }))
  await settle()
  expect(runs).toEqual([])
})

test('中断で終わったターンの後には走らせず、次の正常終了まで持ち越す', async ($, on) => {
  const runs: string[] = []
  on('classic.UserPromptSubmit', () => ({ additionalContext: [REMINDER] }))
  on('command.run', (_, e) => (runs.push(e.command), { text: '' }))
  on('ui.toast', () => ({ value: undefined }))
  on('turn.complete', () => ({ text: '' }))
  await $.classic.UserPromptSubmit({ prompt: 'hi' } as never)
  await $.turn.complete(turn({ reason: 'aborted', isAborted: true }))
  await settle()
  expect(runs).toEqual([])
  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual(['context-save'])
})

test('使用率がしきい値を超えたら、context.md のあるプロジェクトでだけ compact 前に保存する', async ($, on) => {
  const runs: string[] = []
  let hasContext = true
  on('command.run', (_, e) => (runs.push(e.command), { text: '' }))
  on('ui.toast', () => ({ value: undefined }))
  on('turn.complete', () => ({ text: '' }))
  on('session.root', () => ({ value: '/repo' }))
  on('fs.exists', () => ({ value: hasContext }))
  on('session.measure', () => ({ changed: ['context'] }))
  const measure = (percent: number) =>
    $.session.measure({ context: { window: 200_000, tokens: percent * 2000, percent }, rateLimits: [], changed: ['context'] } as never)

  await measure(70)
  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual([])

  await measure(82)
  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual(['context-save'])
  await $.turn.complete(turn()) // 保存のターンの終わり

  // 同じ山の中では 1 回だけ
  await measure(88)
  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual(['context-save'])

  // compact で下がった後、context.md の無いプロジェクトでは走らせない
  hasContext = false
  await measure(30)
  await measure(85)
  await $.turn.complete(turn())
  await settle()
  expect(runs).toEqual(['context-save'])
})
