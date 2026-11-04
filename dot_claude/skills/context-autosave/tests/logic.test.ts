import { expect, test } from 'claude-code/testing'

import { REMINDER_MARK, step, stripReminder, triggerPercent } from '../hooks/logic'

test('保存リマインダーだけを取り除く', () => {
  const r = `<system-reminder>\n${REMINDER_MARK} 300 分経過し…\n</system-reminder>`
  expect(stripReminder(['a', r, 'b'])).toEqual({ rest: ['a', 'b'], found: true })
  expect(stripReminder(['a'])).toEqual({ rest: ['a'], found: false })
})

test('しきい値は 80% と自動 compact の 5 ポイント手前の低い方', () => {
  expect(triggerPercent()).toBe(80)
  expect(triggerPercent(200_000, 180_000)).toBe(80) // 90% - 5 = 85 → 80
  expect(triggerPercent(200_000, 160_000)).toBe(75) // 80% - 5 = 75
})

test('使用率の山ごとに 1 回だけ発火し、15 ポイント下がると戻る', () => {
  let armed = true
  const fires: number[] = []
  for (const p of [70, 81, 85, 90, 70, 64, 82]) {
    const s = step(p, 80, armed)
    armed = s.armed
    if (s.fire) fires.push(p)
  }
  expect(fires).toEqual([81, 82])
})
