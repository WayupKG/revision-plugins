# Revision — плагины для агентов

[Revision](https://revision.replai.kg) — память проекта, которую ведёт агент: задачи, решения и
документы в одном месте. Плагин несёт навык `revision-memory`: когда что записывать и читать.

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
| `plugins/revision/.claude-plugin/plugin.json` | манифест Claude |
| `plugins/revision/.codex-plugin/plugin.json` | манифест Codex |
| `.claude-plugin/marketplace.json` | каталог для Claude |
| `.agents/plugins/marketplace.json` | каталог для Codex |

## Данные

Плагин не хранит и не передаёт ничего сам: всё идёт через MCP-сервер Revision и только в
границах подключения. Подробно —
[политика конфиденциальности](https://revision.replai.kg/privacy),
[условия](https://revision.replai.kg/terms), [поддержка](https://revision.replai.kg/support).
