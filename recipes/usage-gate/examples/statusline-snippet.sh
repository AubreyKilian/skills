# usage-gate snapshot: merge this into an existing status line script.
# POSIX sh; needs jq. Assumes the status line already read Claude Code's JSON
# from stdin into $input (e.g. input=$(cat)). Do not read stdin a second time.
#
# Saves the rate_limits object to ~/.claude/usage.json for the usage-gate hook.
# Writes to a temp file and renames it, so the hook never reads a half-written file.
# Claude Code can kill a status line mid-run, which strands the temp file; the
# find line prunes any stragglers older than 10 minutes.

snap="$HOME/.claude/usage.json"
if printf '%s' "$input" | jq -e '.rate_limits | objects' >/dev/null 2>&1; then
  printf '%s' "$input" | jq -c '{captured_at: (now | floor), rate_limits}' >"$snap.$$" \
    && mv -f "$snap.$$" "$snap"
  rm -f "$snap.$$"
  find "$HOME/.claude" -maxdepth 1 -name 'usage.json.*' -mmin +10 -delete 2>/dev/null
fi
