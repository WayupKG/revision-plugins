# Revision — плагины для агентов

[Revision](https://revision.replai.kg) — память проекта, которую ведёт агент: задачи, решения и
документы в одном месте. Плагин подключает MCP-сервер Revision и навык `revision-memory`, который
говорит агенту, когда что записывать и читать.

Один исходник — два клиента: у плагина манифест Claude (`.claude-plugin/plugin.json`) и манифест
Codex (`.codex-plugin/plugin.json`), а `.mcp.json`, навык и логотип общие.

## Claude (десктоп и Claude Code)

**Десктоп:** Settings → Plugins → Add → **Add from a repository** → `WayupKG/revision-plugins`,
затем установить плагин **Revision**.

**Claude Code:**

```
/plugin marketplace add WayupKG/revision-plugins
/plugin install revision@revision
```

При первом обращении к инструментам откроется вход в Revision и экран согласия. Там выбираются
разрешения (чтение, черновики задач, память и документы) и проекты.

## Codex

```
codex plugin marketplace add WayupKG/revision-plugins
codex plugin add revision@revision
codex mcp login revision
```

Кнопка «Install plugin» в приложении Codex для таких каталогов бывает неактивна — тогда хватает
второй команды. Вход в MCP в Codex сам не начинается: без `codex mcp login revision` навык есть,
а инструментов нет. После входа — новый чат.

## Что внутри

| Файл | Зачем |
| --- | --- |
| `plugins/revision/.mcp.json` | сервер `https://revision.replai.kg/api/v1/mcp`, вход по OAuth |
| `plugins/revision/skills/revision-memory/SKILL.md` | правило работы с памятью проекта |
| `plugins/revision/.claude-plugin/plugin.json` | манифест Claude |
| `plugins/revision/.codex-plugin/plugin.json` | манифест Codex |
| `.claude-plugin/marketplace.json` | каталог для Claude |
| `.agents/plugins/marketplace.json` | каталог для Codex |

## Данные

Плагин не хранит и не передаёт ничего сам: всё идёт через MCP-сервер Revision и только в
границах, выбранных на экране согласия. Подробно —
[политика конфиденциальности](https://revision.replai.kg/privacy),
[условия](https://revision.replai.kg/terms), [поддержка](https://revision.replai.kg/support).
