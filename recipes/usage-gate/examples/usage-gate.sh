#!/usr/bin/env bash
# usage-gate: Claude Code PreToolUse hook (matcher "Agent|Task").
# Blocks subagent spawns while a subscription rate-limit window is nearly used up.
#
# Reads ~/.claude/usage.json, which the status line writes on every refresh.
# Thresholds (percent): USAGE_GATE_5H (default 85), USAGE_GATE_7D (default 95).
#
# Fails open: a missing, unreadable or malformed snapshot lets the spawn through.

snap="$HOME/.claude/usage.json"
cat >/dev/null # drain the hook input; it is not needed
[[ -r $snap ]] || exit 0

reason=$(jq -r --argjson t5 "${USAGE_GATE_5H:-85}" --argjson t7 "${USAGE_GATE_7D:-95}" '
  now as $now
  | [ (.rate_limits.five_hour // empty
        | select(.resets_at > $now and .used_percentage >= $t5)
        | {name: "5-hour", pct: .used_percentage, t: $t5, at: .resets_at}),
      (.rate_limits.seven_day // empty
        | select(.resets_at > $now and .used_percentage >= $t7)
        | {name: "7-day", pct: .used_percentage, t: $t7, at: .resets_at}) ]
  | if length == 0 then empty else
      (max_by(.at)) as $last
      | ($last.at | localtime | strftime("%a %d %b %H:%M")) as $when
      | (map("\(.name) usage \(.pct | floor)% (threshold \(.t)%), resets \(.at | localtime | strftime("%a %d %b %H:%M"))")
         | join("; "))
        + ". Subagent spawn blocked to protect the subscription rate limit."
        + " Do NOT do the subagent'"'"'s work inline instead."
        + " Pause: first tell the user in this session which limit tripped, when it resets ("
        + $when + "), and what work is waiting. Then wait, re-checking periodically, because"
        + " the limit can be reset early (e.g. by the user) and the gate lifts as soon as usage"
        + " drops: in /loop use ScheduleWakeup with at most 3600s per wakeup and retry the spawn on"
        + " each wake; otherwise run this in a background shell and retry the spawn when it exits:"
        + " until [ -z \"$(echo {} | ~/.claude/hooks/usage-gate.sh)\" ]; do sleep 300; done"
        + " (the latest scheduled reset is " + $when + ", epoch \($last.at))."
    end' "$snap" 2>/dev/null)

[[ -z $reason ]] && exit 0
jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
