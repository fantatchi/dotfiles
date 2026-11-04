import { expect, mock, test } from 'claude-code/testing'

import { AUDIT, DRIFT } from './fixtures'

const OTHER = '<system-reminder>\n最後の context 保存から 300 分経過\n</system-reminder>'
const BAND = {
  plugin: 'reminder-band',
  component: 'AbovePrompt',
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 100 },
} as const

async function fire($: Parameters<Parameters<typeof test>[1]>[0], on: Parameters<Parameters<typeof test>[1]>[1]) {
  on('classic.UserPromptSubmit', () => ({ additionalContext: [AUDIT, OTHER, DRIFT] }))
  return $.classic.UserPromptSubmit({ prompt: 'hi' } as never)
}

test('2 種類を帯へ回し、それ以外は Claude に残す', async ($, on) => {
  const result = await fire($, on)
  expect(result.additionalContext).toEqual([OTHER])

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...BAND, surface })
    expect((await ui.find({ type: 'Text', text: /CLAUDE\.md 監査 12 日経過/ }))?.text).toBeTruthy()
    expect((await ui.find({ type: 'Text', text: /chezmoi ドリフト 2 件/ }))?.text).toBeTruthy()
    await ui.unmount()
  }
})

test('「今やる」は依頼文を送って帯から消し、「閉じる」は消すだけ', async ($, on) => {
  const sent: string[] = []
  on('prompt.submit', (_, e) => {
    sent.push(e.text ?? '')
    return { text: e.text }
  })
  // 帯が空になると next(e) へ渡る。その先の engine の描画を代役で立てる
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  await fire($, on)

  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  await ui.press({ key: 'audit-do' })
  expect(sent.length).toBe(1)
  expect(sent[0]).toMatch(/claude-md-improver/)
  expect(await ui.find({ type: 'Text', text: /CLAUDE\.md 監査/ })).toBeFalsy()

  await ui.press({ key: 'drift-close' })
  expect(sent.length).toBe(1)
  expect(await ui.find({ type: 'Text', text: /chezmoi ドリフト/ })).toBeFalsy()
  await ui.unmount()
})

test('リマインダーが無ければ結果をそのまま返し、帯も出さない', async ($, on) => {
  on('classic.UserPromptSubmit', () => ({ additionalContext: [OTHER] }))
  const result = await $.classic.UserPromptSubmit({ prompt: 'hi' } as never)
  expect(result.additionalContext).toEqual([OTHER])
  void mock
})
