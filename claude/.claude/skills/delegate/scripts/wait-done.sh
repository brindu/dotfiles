#!/bin/bash
# Wait until workmux agents finish their work, including background subagents.
#
# Usage: wait-done.sh [--timeout SECONDS] HANDLE...
#
# `workmux wait` is not enough: status `done` means only that the agent's turn
# ended. An agent with background subagents goes `done` while they run, then
# resumes. `workmux status --json` does not show subagents; the pane footer
# does. So a `done` agent counts as idle only when its pane shows no running
# subagent, and all agents must stay idle for 3 polls in a row.
#
# Exit codes:
#   0  all agents done, no subagent running
#   1  timeout
#   2  usage error, or workmux / jq missing
#   3  an agent needs input (`waiting`) or its worktree is gone

timeout=3600
interval=20
quiet_needed=3

while [ $# -gt 0 ]; do
  case $1 in
    --timeout) timeout=$2; shift 2 ;;
    -h|--help) sed -n '2,16s/^# \{0,1\}//p' "$0"; exit 0 ;;
    --) shift; break ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "usage: wait-done.sh [--timeout SECONDS] HANDLE..." >&2
  exit 2
fi
for cmd in workmux jq; do
  command -v "$cmd" >/dev/null || { echo "missing: $cmd" >&2; exit 2; }
done

polls=$(( (timeout + interval - 1) / interval ))
quiet=0
i=0
while [ "$i" -lt "$polls" ]; do
  busy=0
  for h in "$@"; do
    s=$(workmux status "$h" --json 2>/dev/null | jq -r '.agents[0].status // "gone"')
    [ -n "$s" ] || s=gone
    case $s in
      waiting|gone) echo "$h: $s"; exit 3 ;;
      done) workmux capture "$h" -n 15 |
              grep -Eq '◯|Waiting for [0-9]+ background' && busy=1 ;;
      *) busy=1 ;;
    esac
  done
  if [ "$busy" -eq 0 ]; then quiet=$((quiet + 1)); else quiet=0; fi
  [ "$quiet" -ge "$quiet_needed" ] && { echo "all done"; exit 0; }
  sleep "$interval"
  i=$((i + 1))
done
echo "timeout"
exit 1
