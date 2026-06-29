# godot-hex-sim-1

Turn-based **farm management sim** on a hex map (~10 m per tile). You are **head of household**
— assign daily labor across your plots while seasons and weather run the calendar.

## Getting started

1. Install [Godot 4.7](https://godotengine.org/download).
2. Open this folder in Godot.
3. Press **F5** — start screen → **New game**.

Window size: **1280×720**. Scroll to zoom out (patch / block / zone views).

## Tests

```bash
./scripts/run_tests.sh
```

## How to play

**One turn = one day.** Each day you get **2 labor actions** for farm work (plant, tend,
harvest). Click a plot to select it — your farmer walks there for free; only the work costs
labor. End the day or skip time forward when nothing needs doing.

| Action | Effect |
|---|---|
| **Select plot** (click) | Choose which field to work; farmer walks there (free) |
| **Plant wheat / barley** | Uses 1 seed; crop grows over days |
| **Tend** | Protects against drought; helps in frost |
| **Harvest** | Collect food when mature |
| **End day** (Space) | Resolve today: growth, food use, new weather |
| **Skip 7 days** | Fast-forward a week (same daily math) |
| **Skip to work** (Shift+Space) | Advance days until harvest, tend, or plant is needed |

**Calendar:** 91 days per season · 364-day year  
**Food:** household eats **2 food per 7 days** (scaled daily, not lump weekly)  
**Weather:** new roll each day (Clear, Rain, Drought, Frost)

**Crops:**

| Crop | Plant in | Grow | Yield | Notes |
|---|---|---|---|---|
| Wheat | Spring, Autumn | 28 days | 8 food | Frost-sensitive |
| Barley | Spring, Summer | 21 days | 5 food | Frost-tolerant |

## Project layout

```
scenes/start.tscn      Main menu
scenes/options.tscn    Options (placeholder)
scenes/game.tscn       Playable farm scene
tests/unit/            GUT automated tests
scripts/run_tests.sh  Run test suite
addons/gut/           GUT framework
scripts/autoload/     TurnManager, GameState
scripts/farming/      CropDefinition, PlotState
scripts/game/         Main scene UI + input
scenes/               main.tscn, unit.tscn
docs/                 Design docs
```

## Credits

Hex tiles from [godot-demo-projects/2d/hexagonal_map](https://github.com/godotengine/godot-demo-projects/tree/master/2d/hexagonal_map).

## Documentation

See [`docs/`](docs/).
