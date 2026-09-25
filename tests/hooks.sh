#!/bin/sh
# Проверка хуков Revision на подставных событиях Claude Code и Codex.
# Запуск: sh tests/hooks.sh (и тем же sh гоняется сам хук).
set -u
HOOK="$(cd "$(dirname "$0")/.." && pwd)/plugins/revision/hooks/revision-hook.sh"
SH=${SH:-sh}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAILED=0

check() { # название, ожидаемая подстрока ('' — пустой вывод), вывод
  if [ -z "$2" ]; then
    [ -z "$3" ] && echo "ок   $1" || { echo "FAIL $1: ждали пусто, получили: $3"; FAILED=1; }
  else
    case $3 in *"$2"*) echo "ок   $1" ;; *) echo "FAIL $1: нет «$2» в: $3"; FAILED=1 ;; esac
  fi
}
run() { # событие, каталог, json
  printf "%s" "$3" | env -u CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_DATA="$WORK/data" "$SH" ${TRACE:+-x} "$HOOK" "$1"
}

REPO=$WORK/repo
mkdir -p "$REPO/sub" "$WORK/plain"
git -C "$REPO" init -q
printf '{"mcpServers":{"revision":{"type":"http","url":"x"}}}' >"$REPO/.mcp.json"

j1="{\"session_id\":\"s0\",\"cwd\":\"$WORK/plain\"}"
check "не подключённая папка молчит" "" \
  "$(run start "$WORK/plain" "$j1")"
j2="{\"session_id\":\"s1\",\"cwd\":\"$REPO/sub\",\"source\":\"startup\"}"
check "старт сессии в подключённой" "what_changed" \
  "$(run start "$REPO" "$j2")"

commit="{\"session_id\":\"s1\",\"cwd\":\"$REPO\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git add -A && git commit -m \\\"Кнопка\\\\n\\\\nRevision: PXL-1\\\"\"},\"tool_response\":{\"stdout\":\"[main 1a2b] ok\"}}"
check "после коммита — link_commits" "link_commits" "$(run tool "$REPO" "$commit")"
j3="{\"session_id\":\"s1\",\"cwd\":\"$REPO\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git log -1\"},\"tool_response\":{\"stdout\":\"git commit -m x\"}}"
check "git log с «git commit» в выводе — не коммит" "" \
  "$(run tool "$REPO" "$j3")"

stop="{\"session_id\":\"s1\",\"cwd\":\"$REPO\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":false}"
check "конец ответа без записи — спросить" '"decision":"block"' "$(run stop "$REPO" "$stop")"
check "второй раз не спрашивает" "" "$(run stop "$REPO" "$stop")"
j4="{\"session_id\":\"s2\",\"cwd\":\"$REPO\",\"stop_hook_active\":true}"
check "продолжение по просьбе хука — молчит" "" \
  "$(run stop "$REPO" "$j4")"

# Сессия, где память записали, — не спрашиваем.
run tool "$REPO" "{\"session_id\":\"s3\",\"cwd\":\"$REPO\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git -c user.name=t -C app commit -m x\"}}" >/dev/null
run tool "$REPO" "{\"session_id\":\"s3\",\"cwd\":\"$REPO\",\"tool_name\":\"mcp__revision__remember\",\"tool_input\":{\"items\":[]}}" >/dev/null
j5="{\"session_id\":\"s3\",\"cwd\":\"$REPO\",\"stop_hook_active\":false}"
check "записали в память — не спрашивает" "" \
  "$(run stop "$REPO" "$j5")"
j6="{\"session_id\":\"s4\",\"cwd\":\"$REPO\",\"stop_hook_active\":false}"
check "без коммитов — не спрашивает" "" \
  "$(run stop "$REPO" "$j6")"

# Подключение правилами в AGENTS.md (Codex) — без .mcp.json.
CODEX=$WORK/codex
mkdir -p "$CODEX"
printf '# x\n<!-- revision -->\n' >"$CODEX/AGENTS.md"
j7="{\"session_id\":\"c1\",\"cwd\":\"$CODEX\",\"source\":\"startup\"}"
check "Codex: правила в AGENTS.md" "what_changed" \
  "$(run start "$CODEX" "$j7")"

# Вывод — валидный JSON.
j0="{\"session_id\":\"s5\",\"cwd\":\"$REPO\"}"
out=$(run start "$REPO" "$j0")
if printf '%s' "$out" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
  echo "ок   JSON разбирается"
else
  echo "FAIL JSON: $out"; FAILED=1
fi
exit $FAILED
