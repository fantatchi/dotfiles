// reminder-band: UserPromptSubmit hook が Claude へ注入するリマインダーのうち、
// CLAUDE.md 監査と chezmoi ドリフトを横取りし、入力欄の上の帯とボタンでユーザーに直接出す。
// 閾値・スヌーズ・state は各スクリプトが正（SSOT）。この Mod は表示先を変えるだけ。
// Mod が無い・壊れた場合は、従来どおり Claude に注入される（安全側）。
import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Reminder } from '../types'
import { classify, upsert } from './classify'

const items = atom({ plugin: 'reminder-band', key: 'items' } as const, [] as Reminder[], { shape: 'items-1' })

export const register: Register = on => {
  on('classic.UserPromptSubmit', async ($, e, next) => {
    const result = await next(e)
    const contexts = result.additionalContext ?? []
    const caught: Reminder[] = []
    const rest: string[] = []
    for (const c of contexts) {
      const r = classify(c)
      if (r) caught.push(r)
      else rest.push(c)
    }
    if (caught.length === 0) return result
    await update($, items, cur => upsert(cur ?? [], caught))
    return { ...result, additionalContext: rest }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const list = await read($, items)
    if (e.props.hasSurvey || list.length === 0) return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    const drop = (kind: Reminder['kind']) => update($, items, cur => (cur ?? []).filter(r => r.kind !== kind))

    return (
      <Box flexDirection="column" paddingX={1}>
        {list.map(r => (
          <Box key={r.kind} flexDirection="row">
            <Text color="yellow">{`⚑ ${r.summary}  `}</Text>
            <Button
              key={`${r.kind}-do`}
              label="今やる"
              onPress={async () => {
                // 先に帯から消す（送った依頼のターンが終わるまで submit は戻らないことがある）
                await drop(r.kind)
                try {
                  await $.prompt.submit({ text: r.request, asUser: true })
                } catch {
                  await update($, items, cur => upsert(cur ?? [], [r]))
                  $.ui.toast('依頼を送れませんでした。帯に戻しました')
                }
              }}
            />
            <Text>{' '}</Text>
            <Button key={`${r.kind}-close`} label="閉じる" onPress={() => drop(r.kind)} />
          </Box>
        ))}
      </Box>
    )
  })
}
