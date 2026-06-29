# Style Guide

Keep everything minimal: map, turn label, short hints, readable resource consequences. The UI
should support frontier survival decisions without becoming a ledger.

## Principles

- **Simple** - one font, few panels
- **Map first** - hex grid fills the screen
- **Plain language** - "Day 3", "Select hexes", not ornate lore text
- **Explain consequences** - tell the player why resources changed

## Visual

- Frontier palette: earth, water, field, wood, shelter, highlight
- Selection: clear outline/fill on one or more hexes
- HUD: top margin, resource status, actions, one short hint line
- Terrain view should aid reading elevation, not replace map management

## Terms

| Use | Avoid |
|---|---|
| hex, patch, block, zone | league, furlong, custom jargon |
| actor, person | unit, NPC, pawn (in docs) |
| turn, day, labor | AP, stamina |
| provisions, fuelwood, lumber | generic food/wood when specificity matters |
| chore, work zone | magic action, spell, command point |

## Interaction

- Left click - select one hex
- Left drag - box-select hexes
- Right/middle drag - pan
- Q/E - rotate
- R/F - zoom
- V - map/terrain view
- Buttons - assign chores to selected hexes
- Space - end day
- Shift+Space - skip to next day with work

## Accessibility

- `end_turn` on keyboard
- Do not rely on color alone for selection
- Keep failure messages specific: missing labor, season, tool, resource, skill, or legal condition
