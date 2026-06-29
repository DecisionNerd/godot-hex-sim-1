# Testing

Automated tests use [GUT](https://github.com/bitwes/Gut) (v9.5 in `addons/gut/`).

## Run tests

```bash
./scripts/run_tests.sh
```

Or:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

In the editor: **Project → Tools → GUT** (after plugin enabled).

## Strategy

| Layer | Tool | Scope |
|---|---|---|
| Unit | GUT | Calendar, survival resources, farming, turns, RNG, terrain layout |
| Manual | Godot F5 | Map, UI, input |

## Coverage

| Area | Tests |
|---|---|
| `PlotState` | empty, mature, clear |
| Calendar | day-in-season, season/year rollover |
| Farming/survival | plant, harvest, frost, drought, actionable work, trade |
| Food | daily consumption accumulator |
| `TurnManager` | actions, advance days, skip-to-work |
| Weather RNG | same seed gives same sequence |
| Scenario/theme | active scenario, calendar year, west resource names |
| Terrain | layout, picking, scene boot |

## Manual checks

Godot 4.7 -> F5 -> start screen -> New Game.

Check:

- claim selection scene loads
- left-click and left-drag selection work
- Q/E rotate, R/F zoom, WASD pan, right-drag pan
- V toggles map/terrain view
- chores can be assigned to selected hexes
- Work day and End day update resources/logs without script errors

## Test helpers

- `GameState.reset_for_test(seed)` - isolated game state
- `GameState.resolve_day(n)` - end-of-day sim without UI
- `TurnManager.reset_for_test()` - reset turn counter and actions
