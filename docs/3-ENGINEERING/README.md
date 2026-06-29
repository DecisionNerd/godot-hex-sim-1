# Engineering

Technical documentation supporting [`../3-ARCHITECTURE.md`](../3-ARCHITECTURE.md) and
[`../4-TESTING.md`](../4-TESTING.md).

## Index

| Document | Description |
|---|---|
| [setup.md](setup.md) | Godot install, first run, project layout |
| [godot-features.md](godot-features.md) | Engine features to use and avoid |
| [ADRs/](ADRs/) | Architecture Decision Records |

## Decision records

Significant decisions are recorded in [`ADRs/`](ADRs/). To add one manually, copy the template
from an existing ADR (e.g. `0001-hex-map-tilemap-layer.md`) with the next number.

Or use docgen if installed:

```
docgen add adr <short-slug>
```
