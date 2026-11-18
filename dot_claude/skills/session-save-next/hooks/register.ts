import type { Register } from 'claude-code'

const CONTINUE = '続ける（clear → context-load）'
const EXIT = '終了する（/exit）'
const STAY = 'このまま'

export const register: Register = on => {
  // session-save が展開されたターンを覚えておく（/session-save と Skill ツールの両方で発火する）
  let isPending = false

  on('skill.prompt', { skill: 'session-save' }, ($, e, next) => {
    isPending = true
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (!isPending || e.agentId !== undefined) return result
    isPending = false
    if (e.reason !== 'answer') return result

    // ターンの外で聞く（command.run はターンが待つ hook の中からは失敗するため）
    $.clock.after(300, () => {
      void (async () => {
        try {
          const answer = await $.ui.ask('セッションを保存しました。この後どうしますか？', {
            header: '保存後',
            options: [CONTINUE, EXIT, STAY],
          })
          if (answer === CONTINUE) {
            await $.command.run({ command: 'clear' })
            await $.command.run({ command: 'context-load' })
          } else if (answer === EXIT) {
            await $.command.run({ command: 'exit' })
          }
        } catch (err) {
          $.ui.toast(`session-save-next: ${err instanceof Error ? err.message : String(err)}`)
        }
      })()
    })
    return result
  })
}
