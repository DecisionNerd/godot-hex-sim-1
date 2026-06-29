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
| Unit | GUT | Calendar, farming, food, turns, RNG |
| Manual | Godot F5 | Map, UI, input |

## Coverage

| Area | Tests |
|---|---|
| `PlotState` | empty, mature, clear |
| Calendar | day-in-season, season/year rollover |
| Farming | plant, harvest, frost, drought, actionable work |
| Food | 7 days ≈ 2 food consumed |
| `TurnManager` | actions, advance days, skip-to-work |
| Weather RNG | same seed → same sequence |

## Manual checks

Godot 4.7 → F5 → `scenes/main.tscn` — select plot, plant/tend/harvest, end day, Shift+Space skip-to-work.

## Test helpers

- `GameState.reset_for_test(seed)` — isolated farm state
- `GameState.resolve_day(n)` — end-of-day sim without UI
- `TurnManager.reset_for_test()` — reset turn counter and actions
