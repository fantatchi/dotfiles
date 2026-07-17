#!/bin/bash
# Claude Code statusline: model name / git branch / context usage
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

# dim colors (terminal renders statusline dimmed already, but be explicit)
DIM='\033[2m'
RESET='\033[0m'
CYAN='\033[2;36m'
YELLOW='\033[2;33m'
GREEN='\033[2;32m'
MAGENTA='\033[2;35m'

parts=()
parts+=("$(printf "${CYAN}%s${RESET}" "$model")")

if [ -n "$branch" ]; then
  parts+=("$(printf "${YELLOW}%s${RESET}" "$branch")")
fi

if [ -n "$used_pct" ]; then
  ctx=$(printf '%.0f' "$used_pct")
  parts+=("$(printf "${GREEN}Ctx:%s%%${RESET}" "$ctx")")
fi

# Claude.ai サブスクのレート制限使用率（/usage 相当）。未契約 or 初回応答前は該当フィールドが無いので省略
rl_str=""
if [ -n "$five_pct" ]; then
  rl_str="5h:$(printf '%.0f' "$five_pct")%"
fi
if [ -n "$week_pct" ]; then
  wk="7d:$(printf '%.0f' "$week_pct")%"
  if [ -n "$rl_str" ]; then
    rl_str="${rl_str} ${wk}"
  else
    rl_str="$wk"
  fi
fi
if [ -n "$rl_str" ]; then
  parts+=("$(printf "${MAGENTA}%s${RESET}" "$rl_str")")
fi

sep="$(printf "${DIM} | ${RESET}")"
out="${parts[0]}"
for ((i=1; i<${#parts[@]}; i++)); do
  out="${out}${sep}${parts[$i]}"
done
printf '%s\n' "$out"
