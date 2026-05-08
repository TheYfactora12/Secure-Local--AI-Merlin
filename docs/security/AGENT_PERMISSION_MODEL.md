> Moved from `docs/AGENT_PERMISSION_MODEL.md` on 2026-05-06.

# Agent Permission Model

Last updated: 2026-05-08

## Magic Mode v2.2

Magic Mode is a planner, not an executor.

`wizard merlin magic plan "goal"` can describe proposed work and required gates,
but all agent permissions remain denied in the browser and CLI planning layer:

| Permission | Plan Mode | Notes |
| --- | --- | --- |
| `read_files` | denied | Plans may say reading is needed; they do not read. |
| `write_files` | denied | Requires future `file_write` approval and executor. |
| `run_shell` | denied | Requires future `shell_command` approval and executor. |
| `git_operation` | denied | Requires future `git_operation` approval and executor. |
| `use_network` | denied | Requires `external_network`; cloud remains off by default. |
| `use_browser` | denied | Browser automation is not implemented in v2.2. |
| `call_external_api` | denied | Requires explicit API/cloud policy gates later. |
| `write_memory` | denied | Use the existing approved memory boundary only. |
| `install_dependencies` | denied | Installer/package changes stay explicit and tested. |
| `modify_security_settings` | denied | Critical gate; never automatic. |
| `openhands_task` | denied | Critical gate due Docker socket exposure. |
| `webhook_execution` | denied | Explicit gate; no webhook execution from Magic plans. |

Pause and stop in v2.2 are review language only. There is no background task to
pause or stop because no execution starts.
