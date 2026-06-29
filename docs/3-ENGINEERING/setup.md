# Development Setup

1. Install [Godot 4.7](https://godotengine.org/download)
2. Import this repo (folder with `project.godot`)
3. Press **F5** - start screen, then **New Game**

## Tests

```bash
./scripts/run_tests.sh
```

## Controls

| Key | Action |
|---|---|
| Left click | Select one hex |
| Left drag | Box-select hexes |
| Right/middle drag | Pan |
| WASD | Pan by map north/south/east/west |
| Q / E | Rotate view |
| R / F | Zoom in / out |
| V | Toggle map / terrain view |
| Space / Enter | End day |
| Shift+Space | Skip to next day with work |

## Layout

```
scenes/start.tscn      Start menu
scenes/settlement.tscn Claim selection
scenes/game.tscn       Main game scene
scripts/autoload/      TurnManager, GameState, SceneRouter
scripts/game/          Game and settlement scene controllers
scripts/render/        Map, overlay, and terrain renderers
docs/                  Design docs - start at docs/README.md
```

## Design constants

- L0 hex = 10 m - simulation runs here only
- L1 patch / L2 block / L3 zone - aggregate cache (dirty recompute)
- Map gen assigns `hex.patch_id`, `hex.block_id`, `hex.zone_id` once

Full model: [`../3-ARCHITECTURE.md`](../3-ARCHITECTURE.md)
