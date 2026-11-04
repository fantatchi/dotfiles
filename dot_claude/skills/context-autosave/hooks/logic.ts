// context-autosave の判定（$ に触れない純粋関数）。

/** context-save-hooks.js の reminder() の文面をミラー。文面が変わると素通しになり、従来どおり Claude に注入される */
export const REMINDER_MARK = '最後の context 保存またはセッション開始から'

export type Reason = 'interval' | 'compact'

export const REASON_TEXT: Record<Reason, string> = {
  interval: '前回の保存から時間が経ったため',
  compact: '自動 compact が近いため',
}

/** 保存リマインダーを取り除いた残りと、取り除いたかどうか */
export function stripReminder(contexts: readonly string[]): { rest: string[]; found: boolean } {
  const rest = contexts.filter(c => !c.includes(REMINDER_MARK))
  return { rest, found: rest.length !== contexts.length }
}

const TRIGGER_PERCENT = 80
const MARGIN_BEFORE_AUTOCOMPACT = 5
const REARM_DROP = 15

/** 保存を始める使用率（%）: 80% と「自動 compact の発動点の 5 ポイント手前」の低い方 */
export function triggerPercent(window?: number, autoCompactThreshold?: number): number {
  if (!window || !autoCompactThreshold) return TRIGGER_PERCENT
  const auto = (autoCompactThreshold / window) * 100 - MARGIN_BEFORE_AUTOCOMPACT
  return Math.max(1, Math.min(TRIGGER_PERCENT, Math.floor(auto)))
}

/**
 * 使用率の山ごとに 1 回だけ発火させる。
 * armed=true の状態でしきい値を超えたら発火して armed=false。しきい値より 15 ポイント下がったら（compact 後）armed に戻す。
 */
export function step(percent: number, trigger: number, armed: boolean): { fire: boolean; armed: boolean } {
  if (armed && percent >= trigger) return { fire: true, armed: false }
  if (!armed && percent < trigger - REARM_DROP) return { fire: false, armed: true }
  return { fire: false, armed }
}
