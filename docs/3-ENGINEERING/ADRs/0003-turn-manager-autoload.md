# ADR-0003: TurnManager as autoload singleton

## Status

Accepted

## Date

2026-06-28

## Context

Multiple systems (UI, units, future economy/events) need a shared turn counter, action budget,
and phase awareness. Options:

1. **Autoload singleton** (`TurnManager`)
2. **Turn state owned by main scene**, passed by reference
3. **ECS / custom framework**

The project is early-stage with a small number of systems.

## Decision

Implement **`TurnManager` as a Godot autoload** registered in `project.godot`. It owns:

- `turn_number`
- `actions_remaining` / `actions_per_turn`
- `phase` enum (`PLAYER`, `RESOLUTION`)
- Signals: `turn_started`, `turn_ended`, `action_consumed`

Systems call `TurnManager.consume_action()` and `TurnManager.end_turn()`; UI connects to signals.

## Consequences

**Positive**

- Global access without scene tree coupling
- Natural extension point for season pipeline
- Idiomatic Godot pattern for game-wide state

**Negative**

- Hidden dependency from any script to autoload (harder to unit-test in isolation)
- Risk of growing into a god-object — split if season/phase logic expands

**Mitigation:** Extract `GameState` autoload for county data; keep `TurnManager` focused on
clock and action budget.

## References

- `scripts/autoload/turn_manager.gd`
- `project.godot` — `[autoload]` section
