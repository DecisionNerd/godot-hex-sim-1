# ADR-0002: Turn-based grid movement, no physics

## Status

Accepted

## Date

2026-06-28

## Context

The Godot hex demo uses `CharacterBody2D` with `move_and_slide()` for real-time movement. Valley
Claim is a turn-based management/survival sim at ~10 m hex scale: the player assigns **labor**
and chores per day. A worker can cross many hexes in a day; walking is visual feedback, not the
main resource cost.

Alternatives:

1. **Discrete grid placement** (`Node2D` with optional `Tween` walk)
2. **Physics-based movement** with turn gating
3. **Grid stored only in data** with sprites as pure visuals

## Decision

Represent actors as **`Node2D` at hex centers** with no physics bodies or `move_and_slide`.
Click/drag selects hexes; chores and work zones consume labor. Movement feedback can be visual,
but day-scale work remains the cost.

## Consequences

**Positive**

- Matches management-sim mental model (assign work, not tile-hopping)
- Simpler tests: sim state is plot selection + labor, not pathfinding
- No collision layer complexity

**Negative**

- Path preview and range highlighting are custom UI work if needed later
- Long cross-county walks may need faster tween or instant snap at scale

## References

- `scripts/units/actor.gd` - actor visual behavior
- `scripts/game/game.gd` - selection, input, and chore buttons
- Removed demo files: `troll.gd` (CharacterBody2D)
