#!/bin/sh
# Хуки Revision для Claude Code и Codex: память в моменты, которые агент проходит сам.
#
#   start — начало сессии: напомнить, что папка подключена к Revision;
#   tool  — после инструмента: коммит → link_commits, remember → запомнить, что писали;
#   stop  — конец ответа: были коммиты, а в память ничего — спросить один раз.
#
# Только POSIX sh, без jq и python: у людей их может не быть. Вход — JSON события
# на stdin, выход — JSON с additionalContext или decision. Молчит в папках, не
# подключённых к Revision, и никогда не падает: сбой хука не должен мешать работе.

EVENT=$1
INPUT=$(cat | tr '\n' ' ')

field() {
  printf '%s' "$INPUT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

# Папка подключена: сервер revision в .mcp.json или правила Revision в CLAUDE.md / AGENTS.md.
connected() {
  dir=${CLAUDE_PROJECT_DIR:-$(field cwd)}
  [ -n "$dir" ] || dir=$(pwd)
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root=$dir
  [ -f "$root/.mcp.json" ] && grep -q '"revision"' "$root/.mcp.json" && return 0
  for file in "$root/CLAUDE.md" "$root/AGENTS.md"; do
    [ -f "$file" ] && grep -q -e '<!-- revision -->' -e 'MCP-сервер `\{0,1\}revision' "$file" && return 0
  done
  return 1
}

say() {
  # Текст без кавычек и обратных слэшей: JSON собирается руками.
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$1" "$2"
}

connected || exit 0

SESSION=$(field session_id | tr -cd 'A-Za-z0-9._-')
[ -n "$SESSION" ] || SESSION=unknown
STATE_DIR=${CLAUDE_PLUGIN_DATA:-${PLUGIN_DATA:-${TMPDIR:-/tmp}}}/revision-hooks
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
STATE=$STATE_DIR/$SESSION

case $EVENT in
start)
  # Старые пометки — прошлых сессий: не копятся.
  find "$STATE_DIR" -type f -mtime +2 -exec rm -f {} + 2>/dev/null
  say SessionStart "Эта папка подключена к Revision (MCP-сервер revision). Начни работу с what_changed; задачу бери через get_task — с ней придут решения по теме (decisions_to_check), прочти их до кода."
  ;;
tool)
  tool=$(field tool_name)
  case $tool in
  *remember)
    echo remembered >>"$STATE"
    ;;
  Bash | shell | *exec_command*)
    # Только сам git commit, а не его упоминание в выводе: смотрим в команду.
    command=$(printf '%s' "$INPUT" | sed 's/"tool_response".*//' \
      | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*\(".*\)/\1/p')
    if printf '%s' "$command" | grep -Eq 'git( +-[cC] +[^ ]+)* +commit' \
      && ! printf '%s' "$command" | grep -q -e '--dry-run' -e 'commit --help'; then
      echo committed >>"$STATE"
      say PostToolUse "Сделан коммит. Если он по задаче — в сообщении строка «Revision: KEY», затем link_commits с files (git show --name-only --format= HEAD): ответ назовёт записи, чей код изменился, и спросит, что записать в память."
    fi
    ;;
  esac
  ;;
stop)
  # Уже продолжаем по просьбе хука — второй раз не просим.
  printf '%s' "$INPUT" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0
  [ -f "$STATE" ] || exit 0
  grep -q committed "$STATE" || exit 0
  grep -q -e remembered -e asked "$STATE" && exit 0
  echo asked >>"$STATE"
  printf '{"decision":"block","reason":"%s"}\n' "В этой сессии были коммиты, а в память Revision ничего не записано. Если в работе приняли решение (почему так, что отвергли), нашли причину сбоя или приём, который стоит повторять, — запиши одним remember с items. Записывать нечего — скажи об этом одной фразой и заканчивай."
  ;;
esac
exit 0
