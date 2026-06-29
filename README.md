# Valley Claim

Turn-based **frontier survival and settlement sim** on a hex map. You lead a household in the
first Homestead Act settlement scenario: claim land, survive seasons, assign work, gather
resources, build shelter, and improve your holding.

## Getting started

1. Install [Godot 4.7](https://godotengine.org/download).
2. Open this folder in Godot.
3. Press **F5** - start screen -> **New Game**.

Window size: **1440x900**. The map supports hex / patch / block / zone zoom levels and a 3D
terrain view.

## Tests

```bash
./scripts/run_tests.sh
```

## How to play

**One turn = one day.** Select one or more hexes, assign chores, work the day, then resolve
weather, food, fields, resources, and household survival.

| Action | Effect |
|---|---|
| **Left click** | Select one hex |
| **Left drag** | Box-select hexes |
| **Right/middle drag** | Pan |
| **WASD** | Pan by map north/south/east/west |
| **Q / E** | Rotate view |
| **R / F** | Zoom in / out |
| **V** | Toggle terrain view |
| **Gather / Clear / Water / Snare / Build / Field** | Assign chores to selected hexes |
| **Work day** | Spend labor on marked chores |
| **End day** (Space) | Resolve today: growth, food use, new weather |
| **Skip 7 days** | Fast-forward a week (same daily math) |
| **Skip to work** (Shift+Space) | Advance days until harvest, tend, or plant is needed |

**Calendar:** 91 days per season · 364-day year  
**Food:** household eats over time (scaled daily, not lump weekly)  
**Weather:** new roll each day (Clear, Rain, Drought, Frost)

**Crops:**

| Crop | Plant in | Grow | Yield | Notes |
|---|---|---|---|---|
| Corn | Spring, Summer | scenario-tuned | provisions | Warm-season staple |
| Beans | Spring, Summer | scenario-tuned | provisions | Companion staple |

## Project layout

```
scenes/start.tscn      Main menu
scenes/options.tscn    Options (placeholder)
scenes/settlement.tscn Claim selection
scenes/game.tscn       Main game scene
tests/unit/            GUT automated tests
scripts/run_tests.sh  Run test suite
addons/gut/           GUT framework
scripts/autoload/     TurnManager, GameState
scripts/farming/      CropDefinition, PlotState
scripts/game/         Main scene UI + input
scripts/render/       Map, overlay, terrain renderers
docs/                 Design docs
```

## Credits

Hex tiles from [godot-demo-projects/2d/hexagonal_map](https://github.com/godotengine/godot-demo-projects/tree/master/2d/hexagonal_map).

## Documentation

See [`docs/`](docs/).
