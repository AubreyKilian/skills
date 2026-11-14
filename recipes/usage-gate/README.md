# Usage gate: pause subagents near your rate limit

A Claude Code hook that blocks subagent spawns when your subscription's **5-hour** or **7-day** usage window passes a threshold. Instead of using up the limit, the session reports in and **pauses until the window resets**, then carries on. It is meant for long, unattended runs that spawn many subagents.

**To install:** give this page to Claude Code and ask it to set this up:

> Set up the usage gate from https://github.com/AubreyKilian/skills/blob/main/recipes/usage-gate/README.md

The rest of this page is written for the Claude Code session doing the setup.

---

## How it works

```
Claude Code ──stdin JSON──▶ status line ──writes──▶ ~/.claude/usage.json
                                                         │ reads
Agent/Task tool call ──▶ PreToolUse hook (usage-gate.sh) ┘──▶ allow, or deny with instructions
```

Hooks are not given rate-limit data, but the status line is: Claude Code pipes JSON with a `rate_limits` object into the status line command on every refresh. So the status line saves that object to a file, and the hook reads the file.

`rate_limits` looks like this (both windows are optional; `resets_at` is epoch seconds):

```json
{"five_hour": {"used_percentage": 42, "resets_at": 1794020400},
 "seven_day": {"used_percentage": 61, "resets_at": 1794362400}}
```

When a window is at or over its threshold and has not reset yet, the hook denies the spawn. The deny reason tells Claude to report the situation to the user in the session, then pause and keep re-checking the gate until it lifts, then retry.

The pause re-checks instead of sleeping until the scheduled reset time because limits can be reset early: for example, Anthropic sometimes offers users a button to reset their limits. The status line picks up the new usage on its next refresh, the gate stops denying, and the paused session resumes within minutes rather than days later.

## Rules to preserve

Whatever you adapt, keep these properties:

1. **Fail open.** If the snapshot is missing, unreadable or malformed, or jq fails, the hook exits 0 with no output and the spawn goes ahead. A broken gate must never block work.
2. **No inline workaround.** The deny reason must tell Claude not to do the subagent's work itself. Without that, the session just does the same work in the main context, and nothing is saved.
3. **Pause, don't stop.** The deny reason must say to report in the session, then wait and retry, even when the reset is days away (the 7-day window). The point is that a long run survives hitting the limit.
4. **Re-check while paused.** The wait must poll the gate (in the `/loop` case, a retry on each wakeup) rather than sleep until the scheduled reset, so an early reset is picked up.
5. **Merge, never overwrite.** The user's `settings.json` and status line script are theirs. Add to them; do not replace them.

## Setup steps

1. **Check for `jq`** (`command -v jq`). If it is missing, ask the user to install it before continuing. Both scripts need it.
2. **Install the hook.** Copy [`examples/usage-gate.sh`](examples/usage-gate.sh) to `~/.claude/hooks/usage-gate.sh` **as written** and make it executable. It has nothing machine-specific in it; thresholds come from environment variables. Do not rewrite it.
3. **Add the snapshot to the status line.** Look for a `statusLine` entry in `~/.claude/settings.json`.
   - **If one exists**, open the script it runs and merge in the logic from [`examples/statusline-snippet.sh`](examples/statusline-snippet.sh), adapted to that script's language and style. It must reuse the JSON the script already read from stdin (stdin can only be read once), write to a temp file and rename it into place, and prune old temp files. Do not change what the status line displays.
   - **If none exists**, ask the user whether they want a minimal status line. If so, create `~/.claude/statusline.sh` that reads stdin into `$input`, runs the snippet, and prints something short (e.g. the model name and the two usage percentages). Make it executable.
   - Set `"refreshInterval": 60` on the `statusLine` entry if it has none. Without it the status line only refreshes when the conversation changes, so a paused session would never see an early reset.
4. **Register the hook.** Merge the `PreToolUse` entry from [`examples/settings-snippet.json`](examples/settings-snippet.json) into `~/.claude/settings.json`, keeping every existing hook. If there is already a `PreToolUse` entry with matcher `Agent|Task`, add the command to it rather than creating a duplicate matcher.
5. **Thresholds.** Ask the user what percentages they want for the 5-hour and 7-day windows (defaults 85 and 95) and set `USAGE_GATE_5H` / `USAGE_GATE_7D` in the `env` block of `settings.json`. Skip the `env` entries if they keep the defaults.
6. **Use absolute paths if needed.** The snippets use `$HOME`. If the user's existing hook commands use absolute paths, follow that convention.

## Test it

Settings changes to hooks and the status line take effect in a new session. Ask the user to restart Claude Code, then:

1. Confirm `~/.claude/usage.json` exists and contains `rate_limits` after the status line has refreshed. If it never appears, the status line isn't receiving `rate_limits` (see Limits below).
2. Test the hook directly with a 0% threshold; it should print a JSON deny decision:
   ```sh
   echo '{}' | USAGE_GATE_5H=0 ~/.claude/hooks/usage-gate.sh
   ```
3. Run it with the normal thresholds; it should print nothing (unless the user really is over a threshold).
4. Optionally, set `USAGE_GATE_5H` to `0` in settings, start a session, ask for a subagent and confirm the spawn is blocked with the pause instructions. Then put the threshold back.

## Limits

- **Only `Agent` and `Task` calls are gated.** Work the main session does itself still uses the limit.
- **The snapshot is only as fresh as the last status line refresh.** Usage within a window only goes up until it resets, so an old snapshot never blocks wrongly; it can only under-report and let a spawn through. Headless runs (`claude -p`) have no status line, so the snapshot isn't updated by them.
- **`rate_limits` only appears for subscription accounts** (Pro/Max), and only once Claude Code has usage data. With API-key billing there is nothing to gate on, and the hook lets everything through.
- **Early resets are detected from the status line data.** This assumes an early reset shows up in `rate_limits` as lower `used_percentage`. If it ever didn't, the pause would still end at the scheduled reset time.
- **A pause lasts only as long as the session.** If Claude Code exits, the pause is lost. If the machine sleeps, the wake-up can come late.
