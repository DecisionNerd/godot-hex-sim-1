<!-- LLM: This is the entry point to the project's documentation. Keep it short and
navigational. Do NOT interview the user for this file first — fill it in last, once the
other docs exist, so the descriptions match what was actually written. Remove LLM comments
as you complete each section. -->

# Documentation

This folder holds the living documentation for this project. It is structured for
**behavior-driven development**: each document builds on the one before it, from *why the
project exists* down to *how we prove it works*. The docs are kept in-repo on purpose so
that both people and AI coding agents have the full context — the mission, the intended
experiences, the requirements, the design guidance, the architecture, and the decisions
behind them — without reaching for an external source.

## How the docs are organized

Read them in order. Each numbered document answers one question:

| Document | Question it answers |
|---|---|
| [`0-MISSION.md`](0-MISSION.md) | Why does this project exist? |
| [`1-EXPERIENCES.md`](1-EXPERIENCES.md) | What should it feel like to use? |
| [`2-REQUIREMENTS.md`](2-REQUIREMENTS.md) | What must the system do? |
| [`3-ARCHITECTURE.md`](3-ARCHITECTURE.md) | How is the system built? |
| [`4-TESTING.md`](4-TESTING.md) | How do we prove it works? |

Supporting detail lives in subfolders, each with its own README:

| Folder | Contents |
|---|---|
| [`0-PRODUCT/`](0-PRODUCT/) | Product, market, and mission detail beyond `0-MISSION.md`. |
| [`1-JOURNEYS/`](1-JOURNEYS/) | User personas, journeys, and experience detail. |
| [`2-DESIGN/`](2-DESIGN/) | Product design, style, accessibility, and component guidance. |
| [`3-ENGINEERING/`](3-ENGINEERING/) | Technical documentation, including testing and decision records. |
| [`3-ENGINEERING/ADRs/`](3-ENGINEERING/ADRs/) | Architecture Decision Records. |

## Conventions

- **Keep docs current.** When behavior changes, update the doc in the same change.
- **Link, don't duplicate.** Reference detail in subfolders rather than copying it.
- **Decisions are recorded.** Significant choices get an ADR (see `3-ENGINEERING/ADRs/`).
