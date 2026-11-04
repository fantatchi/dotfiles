export type ReminderKind = 'audit' | 'drift'

export type Reminder = {
  kind: ReminderKind
  /** 帯に出す 1 行 */
  summary: string
  /** 「今やる」で送る依頼文 */
  request: string
}

declare module 'claude-code' {
  interface PluginState {
    'reminder-band': { items: Shaped<Reminder[]> }
  }
}
