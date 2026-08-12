# crush

Crush loads config in precedence order from `.crush.json`, `crush.json`, then `~/.config/crush/crush.json`, with environment overrides for global config/data. It discovers Skills in canonical Crush, common Agent Skills, Claude, and Cursor locations.

Use `~/.config/crush/skills` and `.crush/skills` as canonical write targets. Merge only the MCP subobject in the selected config file. `$HOME/.local/share/crush` and `CRUSH_GLOBAL_DATA` identify generated application state and are never migration sources.

Source: [Crush repository and configuration](https://github.com/charmbracelet/crush).
