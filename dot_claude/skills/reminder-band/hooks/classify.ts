// UserPromptSubmit hook の注入文から、帯に回すリマインダーを判定する（$ に触れない純粋関数）。
// 判定の文面は ~/.claude/scripts/{claude-md-audit,chezmoi-drift}-reminder.sh の出力をミラーする。
// 文面が変わって判定できなくなっても、素通しされ Claude に注入される（握りつぶさない）方向に倒れる。
import type { Reminder } from '../types'

export function classify(context: string): Reminder | undefined {
  const audit = context.match(/CLAUDE\.md の最終監査から (\d+) 日経過/)
  if (audit) {
    return {
      kind: 'audit',
      summary: `CLAUDE.md 監査 ${audit[1]} 日経過`,
      request:
        'グローバル CLAUDE.md（~/.local/share/chezmoi/dot_claude/CLAUDE.md）を claude-md-improver で監査して。' +
        '終わったら ~/ObsidianVault/00_meta/claude-state.md の last_audit / last_audit_at を更新して。',
    }
  }
  const drift = context.match(/chezmoi のドリフト（source と target の差分）が (\d+) 件あります:\s*\n+\s*(\S+\s+\S+)/)
  if (drift) {
    return {
      kind: 'drift',
      summary: `chezmoi ドリフト ${drift[1]} 件（${drift[2]}${Number(drift[1]) > 1 ? ' ほか' : ''}）`,
      request: 'chezmoi のドリフトを突合して片付けて。',
    }
  }
  return undefined
}

/** 同じ種類は新しい方で上書きし、種類の順（audit → drift）に並べる */
export function upsert(items: readonly Reminder[], next: readonly Reminder[]): Reminder[] {
  const byKind = new Map(items.map(r => [r.kind, r]))
  for (const r of next) byKind.set(r.kind, r)
  return (['audit', 'drift'] as const).flatMap(k => byKind.get(k) ?? [])
}
