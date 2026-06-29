# Development setup

1. Install [Godot 4.7](https://godotengine.org/download)
2. Import this repo (folder with `project.godot`)
3. Press **F5** — main scene `scenes/main.tscn`

## Tests

```bash
./scripts/run_tests.sh
```

## Controls

| Key | Action |
|---|---|
| Left click | Select farm plot (farmer walks there, free) |
| Space / Enter | End day |
| Shift+Space | Skip to next day with work |

## Layout

```
scenes/main.tscn       Entry
scripts/autoload/      TurnManager
scripts/units/unit.gd  Farmer visual on map (free walk; rename to Actor planned)
tileset.tres           Hex grid (~10 m per hex in sim design)
docs/                  Design docs — start at docs/README.md
```

## Design constants

- L0 hex = 10 m — **simulation runs here only**
- L1 patch / L2 block / L3 zone — aggregate cache (dirty recompute)
- Map gen assigns `hex.patch_id`, `hex.block_id`, `hex.zone_id` once

Full model: [`../3-ARCHITECTURE.md`](../3-ARCHITECTURE.md)
