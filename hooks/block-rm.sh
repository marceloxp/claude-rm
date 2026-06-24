#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) — claude-rm project.
#
# Rule: Claude must NEVER run 'rm'. To delete a file, it uses:
#     claude-rm <file>
# (one file at a time, no directories; goes to the restorable system trash via
# 'gio trash').
#
# 'claude-rm' stays ALLOWED: in command position the segment starts with
# "claude", not "rm", so it does not match the rule below.
#
# Default: allow (exit 0). Blocking is done via JSON permissionDecision=deny.

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$cmd" ] && exit 0

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Split into segments (chained ; | & && ||, subshells $( ), backticks) so each
# command is analyzed on its own — that way `foo && rm x` is caught too.
segments="$(printf '%s' "$cmd" | sed -E 's/\$\(/\n/g; s/[;|&`]/\n/g; s/\|\|/\n/g; s/&&/\n/g')"

while IFS= read -r seg; do
  # Is the segment's COMMAND 'rm' (in command position; tolerating sudo/time/VAR= before)?
  # 'claude-rm ...' does not trigger because the segment starts with "claude".
  if printf '%s' "$seg" | grep -qE '^[[:space:]]*(sudo[[:space:]]+|time[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*rm([[:space:]]|$)'; then
    deny "Blocked (claude-rm project): Claude does not run 'rm'. Use 'claude-rm <file>' — one file at a time, no directories; it goes to the restorable trash ('gio trash --restore' undoes it)."
  fi
done <<EOF
$segments
EOF

exit 0
