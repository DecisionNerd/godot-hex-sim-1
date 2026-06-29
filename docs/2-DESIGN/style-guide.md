# Style Guide

Keep everything minimal: map, turn label, short hints. No ornate UI in v1.

## Principles

- **Simple** — one font, few panels
- **Map first** — hex grid fills the screen
- **Plain language** — "Day 3", "Select a plot", not lore text

## Visual

- Default Godot theme until custom art
- Selection: light tint on hex (planned)
- HUD: top margin, turn + one hint line

## Terms

| Use | Avoid |
|---|---|
| hex, patch, block, zone | league, furlong, custom jargon |
| actor, person | unit, NPC, pawn (in docs) |
| turn, day, labor | AP, stamina |

## Interaction

- Click farm plot — select field; farmer walks there (free)
- Buttons — plant / tend / harvest on selected plot (costs labor)
- Space — end day
- Shift+Space — skip to next day with work

## Accessibility

- `end_turn` on keyboard (done)
- Don't rely on color alone for selection (add outline when highlighting exists)
