// context-autosave: context-save を自動で実行する。
// ① 保存リマインダー（context-save-hooks.js の reminder()、UserPromptSubmit）を横取りし、
//    ユーザーの依頼に答えたターンの後で保存させる（今はプロンプトの頭で割り込んでいる）。
// ② コンテキスト使用率が自動 compact の手前に来たら、そのターンの後で保存させる。
// 条件判定 ① はスクリプトが正。Mod が無い・壊れた場合は従来どおり割り込みで保存される（安全側）。
import type { EngineInterface, Register } from 'claude-code'

import { REASON_TEXT, stripReminder, step, triggerPercent, type Reason } from './logic'

// リロードで消えても、① は次の注入で、② は次の measure で立ち直るのでモジュール変数で持つ
let pending: Reason | undefined
// 保存を依頼してから、その保存のターンが終わるまで true。依頼した /context-save 自体の送信でも
// リマインダーが再び注入されるため、この間は pending を立てない（立てると 2 回保存される）
let saving = false
let armed = true
let trigger = triggerPercent()

async function usesContextSave($: EngineInterface): Promise<boolean> {
  try {
    const root = await $.session.root()
    return await $.fs.exists(`${root}/.claude/context.md`)
  } catch {
    return false
  }
}

async function save($: EngineInterface, reason: Reason): Promise<void> {
  $.ui.toast(`context を保存します（${REASON_TEXT[reason]}）`)
  try {
    await $.command.run({ command: 'context-save' })
  } catch {
    await $.prompt.submit({ text: 'context-save スキルを実行して、最新の作業状態を保存して。' })
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    pending = undefined
    saving = false
    armed = true
    try {
      const { context } = await $.session.usage({ breakdown: 'summary' })
      trigger = triggerPercent(context.window, context.breakdown?.autoCompactThreshold)
    } catch {
      trigger = triggerPercent()
    }
    return result
  })

  on('classic.UserPromptSubmit', async ($, e, next) => {
    const result = await next(e)
    const { rest, found } = stripReminder(result.additionalContext ?? [])
    if (!found) return result
    if (!saving) pending = pending ?? 'interval'
    return { ...result, additionalContext: rest }
  })

  on('session.measure', async ($, e, next) => {
    const result = await next(e)
    const percent = e.context.percent
    if (!e.changed.includes('context') || percent === undefined) return result
    const s = step(percent, trigger, armed)
    armed = s.armed
    if (s.fire && !saving && (await usesContextSave($))) pending = 'compact'
    return result
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId) return result
    if (saving) {
      // 保存のターンが終わった。保存で条件が消えるので、次からまた判定してよい
      saving = false
      pending = undefined
      return result
    }
    // 中断（Esc）やエラーで終わったターンの直後には走らせず、次に正常に終わったターンまで持ち越す
    if (!pending || e.reason !== 'answer') return result
    const reason = pending
    pending = undefined
    saving = true
    void save($, reason)
    return result
  })
}
