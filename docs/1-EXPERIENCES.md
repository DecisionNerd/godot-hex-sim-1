# Experiences

Hex map, turns, actors you control, persons that roll on turn end. Zoom out → patches, blocks,
zones (same world, simpler drawing).

## Key experiences

### Select plot and work (done)

- **Given** labor left → **When** click a farm plot → **Then** plot selected, farmer walks there (free)
- **Given** plot selected → **When** plant / tend / harvest → **Then** consume one labor action

### End day (done)

### Zoom the map (planned)

> **As a** player  
> **I want** zoom to change detail, not a different world  
> **So that** I see hexes up close and zones when far out

- **Given** the county map
- **When** I zoom in or out
- **Then** renderer shows hexes, patches, blocks, or zones from the same sim data

### See spread on the map (planned)

- **Given** disease (or similar) on a hex
- **When** turns pass
- **Then** neighbor hexes change first; patch/block/zone summaries update after the tick

## Principles

- Sim on hexes; summaries are derived
- Deterministic persons (seeded)
- Simple
