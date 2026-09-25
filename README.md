# Revision — плагины для агентов

[Revision](https://revision.replai.kg) — память проекта, которую ведёт агент: задачи, решения и
документы в одном месте. Плагин несёт навык `revision-memory` — когда что записывать и читать — и сценарии-команды.

**Подключение к Revision плагин больше не ставит (с 0.3.0).** Сервер из плагина видел все проекты
сразу и в папке с кодом оказывался рядом с подключением проекта — у агента было два-три набора
одинаковых инструментов. Теперь подключение задаётся явно.

## Подключение

**К одному проекту — файлом в репозитории.** В Revision откройте проект → «Обзор» → «Агент в
репозитории»: там готовый файл для Claude Code (`.mcp.json`), Codex (`.codex/config.toml`), Cursor
и VS Code с адресом `https://revision.replai.kg/api/v1/mcp/projects/<id>`. Закоммитьте его — агент
в этой папке с первого вызова работает только в этом проекте, у всех, кто откроет репозиторий.

**Ко всем проектам** — там, где папки нет:
- claude.ai, десктоп Claude, телефон — коннектор: адрес `https://revision.replai.kg/api/v1/mcp`;
- Claude Code вне проекта — `claude mcp add --transport http --scope user revision https://revision.replai.kg/api/v1/mcp`;
- Codex — `codex mcp add revision --url https://revision.replai.kg/api/v1/mcp`, затем `codex mcp login revision`.

Если в Claude Code подключён коннектор claude.ai «revision», в папке проекта выключите его один раз:
`/mcp` → `claude.ai revision` → Disable. Claude Code запомнит это для папки.

## Сценарии

Команды, которые запускает человек (агент сам их не вызывает):

| Команда | Что делает |
| --- | --- |
| `/revision:onboard [папка]` | Перенести в Revision знания, которые уже лежат в репозитории: Obsidian vault, `docs/`, ADR, README. Сначала показывает план; повторный запуск обновляет перенесённое, а не дублирует |
| `/revision:save` | Сохранить итог работы: решения, причины сбоев, приёмы; привязать коммиты, поправить документы, предложить статусы задач |
| `/revision:task RV-42` | Взять задачу: решения по ней, план, коммиты со строкой `Revision: RV-42`, черновик «готово» |
| `/revision:start` | Что изменилось с прошлого раза, что в работе, на что обратить внимание |

Те же сценарии сервер Revision отдаёт промптами MCP — без плагина они есть у любого клиента
(в Claude Code: `/mcp__revision__onboard` и т. д.). Тексты — одни: навыки собираются из
`revision-server/src/revision/modules/mcp/scenarios/` скриптом `scripts/plugin_skills.py`.

## Хуки (с 0.6.0)

Правило «записывай, когда решено» агент в работе забывает: на живых проектах он вёл задачи и
коммиты сам, но не записал ни одного решения. Хуки напоминают в моменты, которые агент проходит
всегда, — в Claude Code и Codex:

| Момент | Что говорит агенту |
| --- | --- |
| начало сессии | папка подключена к Revision: начни с `what_changed`, задачу бери через `get_task` |
| после `git commit` | коммит по задаче — строка `Revision: KEY` и `link_commits` (его ответ спросит, что записать) |
| конец ответа | были коммиты, а в память ничего — один раз спросить, что стоит записать; нечего — закончить |

Хуки молчат в папках, не подключённых к Revision: признак — сервер `revision` в `.mcp.json` или
правила Revision в `CLAUDE.md` / `AGENTS.md`. Работают локально, без сети; POSIX `sh`, без `jq`.
Ничего не блокируют и за сессию спрашивают о записи не больше одного раза.

**Codex** выполняет хуки плагина только после того, как вы их просмотрите и отметите доверенными.
Cursor хуки из плагинов не берёт.

Проверка: `sh tests/hooks.sh`.

## Навык

**Claude (десктоп и Claude Code):**

```
/plugin marketplace add WayupKG/revision-plugins
/plugin install revision@revision
```

Десктоп: Settings → Plugins → Add → **Add from a repository** → `WayupKG/revision-plugins`.

**Codex:**

```
codex plugin marketplace add WayupKG/revision-plugins
codex plugin add revision@revision
```

## Что внутри

| Файл | Зачем |
| --- | --- |
| `plugins/revision/skills/revision-memory/SKILL.md` | правило работы с памятью проекта |
| `plugins/revision/skills/{onboard,save,task,start}/SKILL.md` | сценарии; собраны из сервера — руками не править |
| `plugins/revision/hooks/` | хуки для Claude Code и Codex: `hooks.json` и общий скрипт |
| `plugins/revision/.claude-plugin/plugin.json` | манифест Claude |
| `plugins/revision/.codex-plugin/plugin.json` | манифест Codex |
| `.claude-plugin/marketplace.json` | каталог для Claude |
| `.agents/plugins/marketplace.json` | каталог для Codex |

## Данные

Плагин не передаёт ничего сам (хуки пишут только локальную пометку «в сессии был коммит»): всё идёт через MCP-сервер Revision и только в
границах подключения. Подробно —
[политика конфиденциальности](https://revision.replai.kg/privacy),
[условия](https://revision.replai.kg/terms), [поддержка](https://revision.replai.kg/support).
