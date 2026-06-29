# ADR-0002: Turn-based grid movement, no physics

## Status

Accepted

## Date

2026-06-28

## Context

The Godot hex demo uses `CharacterBody2D` with `move_and_slide()` for real-time movement. Hex Sim
is a **management sim** at ~10 m hex scale: the player assigns **labor** (plant, tend, harvest)
per day. A farmer can cross hundreds of hexes per day — **walking is visual only**, not a
resource cost.

Alternatives:

1. **Discrete grid placement** (`Node2D` with optional `Tween` walk)
2. **Physics-based movement** with turn gating
3. **Grid stored only in data** with sprites as pure visuals

## Decision

Represent the household member as **`Node2D` at hex centers** — **no physics bodies or
`move_and_slide`**. Click a farm plot to select it; `walk_to()` tweens the sprite for feedback.
Only farm labor calls `TurnManager.consume_action()`.

## Consequences

**Positive**

- Matches management-sim mental model (assign work, not tile-hopping)
- Simpler tests: sim state is plot selection + labor, not pathfinding
- No collision layer complexity

**Negative**

- Path preview and range highlighting are custom UI work if needed later
- Long cross-county walks may need faster tween or instant snap at scale

## References

- `scripts/units/unit.gd` — `walk_to()`, `_snap_to_hex`
- `scripts/game/main.gd` — plot selection, labor buttons
- Removed demo files: `troll.gd` (CharacterBody2D)
