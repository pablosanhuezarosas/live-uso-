# Claude Usage — Pablo (Swift/SwiftBar edition)

Monitor de barra de menú de macOS para [Claude Code](https://claude.com/product/claude-code), construido con [SwiftBar](https://github.com/swiftbar/SwiftBar). Muestra estado en vivo, costo real de sesión y uso de cuenta (5h/7d), con estética terminal vintage.

Por Pablo Sanhueza Rosas.

## Qué hace

| Plugin | Refresco | Qué muestra |
|---|---|---|
| `menubar/claude-status.1s.sh` | 1s | Estado en vivo: `NOP` (idle), `RUN` (ejecutando), `INT` (esperando permiso, parpadea), `RET` (tarea OK), `HLT` (error). Incluye un menú **SETTINGS** para elegir qué sonido usa cada evento y ajustar el volumen (ver abajo). |
| `menubar/claude-usage.15s.sh` | 15s | Cuenta regresiva hasta el reset de la ventana de 5h; costo real de la sesión actual (tokens exactos del transcript local + pricing oficial vigente) disponible en el dropdown |
| `menubar/claude-account.60s.sh` | 60s | Uso real de cuenta: ventana de 5 horas y 7 días (via el endpoint OAuth de Anthropic), con alertas sonoras en 20/50/75/90/95% |

### Menús SETTINGS (sonidos y volumen)

Cada plugin que reproduce sonido tiene su **propio** menú SETTINGS, con estado independiente — cambiar uno no afecta al otro.

**`claude-status.1s.sh`** (hooks de permission/success/error):
- **Sonido por evento**: lista cualquier `.mp3` en `~/.claude/sounds/` y lo asigna con un click — copia el archivo elegido sobre el nombre fijo que los hooks invocan (`permission.mp3`, `success.mp3`, `error.mp3`), así que nunca hace falta tocar `settings.json` de nuevo.
- **Volumen** (10%–100%): `~/.claude/sound-volume.txt`, leído dinámicamente por los hooks.
- Requiere `scripts/set-sound.sh` + `scripts/set-volume.sh`.

**`claude-account.60s.sh`** (alertas de 20/50/75/90/95%):
- **Sonido de alerta**: mismo mecanismo, target fijo `account-alert.mp3`.
- **Volumen de alerta** (10%–100%): `~/.claude/account-alert-volume.txt`, independiente del de arriba.
- Requiere `scripts/set-account-sound.sh` + `scripts/set-account-volume.sh`.

Ambos pares de scripts guardan qué sonido está activo en `~/.claude/sound-settings.json` (claves `permission`/`success`/`error`/`account_alert`).

## Cómo funciona (fuentes de datos)

- **Costo de sesión** (`scripts/claude-usage.js`): lee el transcript `.jsonl` más reciente en `~/.claude/projects/**/*.jsonl` — Claude Code escribe ahí el uso exacto de tokens por mensaje (`input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`). El script aplica el pricing oficial vigente por modelo. El contexto (`ctx_pct`) es una aproximación contra la ventana completa del modelo (1M para Sonnet 5), **no es idéntico** al indicador nativo de la extensión de VSCode (que usa un umbral distinto, no documentado públicamente).

- **Uso de cuenta 5h/7d** (`scripts/claude-account-usage.sh`): pega directo a `https://api.anthropic.com/api/oauth/usage`, reutilizando el mismo token OAuth que Claude Code ya guarda en el Keychain de macOS (`security find-generic-password -s "Claude Code-credentials"`). **Este endpoint no está documentado oficialmente** — puede cambiar o dejar de funcionar sin aviso.

## Instalación

1. Instalá [SwiftBar](https://github.com/swiftbar/SwiftBar): `brew install --cask swiftbar`
2. Copiá el contenido de `menubar/` a la carpeta de plugins que elijas para SwiftBar (configurable en sus preferencias), y `scripts/` a `~/.claude/scripts/`
3. Dale permisos de ejecución: `chmod +x menubar/*.sh scripts/*.sh`
4. (Opcional) Agregá los hooks de sonido descritos en `hooks-settings-snippet.json` a tu `~/.claude/settings.json`, y poné tus propios archivos de audio en `~/.claude/sounds/` (`permission.mp3`, `success.mp3`, `error.mp3` — **no incluidos en este repo**, son efectos de sonido con copyright de terceros)
5. Dependencias: `bash`, `jq`, `python3`, `node`, `curl` (todas suelen venir con macOS o Homebrew)

## Limitaciones conocidas

- El dropdown de SwiftBar es un `NSMenu` nativo de macOS: se puede customizar color/fuente/tamaño de cada línea, pero **no** el marco o fondo del panel.
- El endpoint `api/oauth/usage` es interno/no documentado. Si Anthropic lo cambia, `claude-account.180s.sh` va a mostrar `5H[----------]--%` — no es un bug del script.
- El `% de contexto` de `claude-usage.15s.sh` es una aproximación (tokens reales / ventana completa del modelo), no replica exactamente el indicador nativo de la extensión de VSCode.

## Licencia

MIT — ver `LICENSE`. Esto es tooling propio que interactúa con Claude Code; no incluye ni redistribuye código de la extensión de Anthropic.
