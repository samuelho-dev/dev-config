---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain the domain model.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* the canonical domain glossary for vocabulary is not this skill — that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## File structure

First inspect project instructions and existing domain documents, including `GLOSSARY.md`/`GLOSSARY-MAP.md`, `CONTEXT.md`/`CONTEXT-MAP.md` and the documented ADR directory. Follow the established canonical documents and their links; these filenames are conventions, not portable Agent Skills requirements. If both forms exist, use documented authority; if authority is unclear, ask before writing. Never create a second competing glossary/map or rename consumer files as an implicit migration.

The `CONTEXT` names below are this curated collection's fallback only when the project has no established convention. Current upstream uses `GLOSSARY` names; retaining this local default does not claim upstream identity. Use the selected canonical glossary throughout the session, not the fallback filename.

A single-context fallback looks like:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

For multiple contexts, follow the canonical map's links. The curated fallback map is `CONTEXT-MAP.md`, which points to each context's glossary:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily, only after resolving canonical ownership. When no domain convention exists, create the fallback `CONTEXT.md` for the first resolved term. Follow the established ADR directory; `docs/adr/` is only the fallback when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in the canonical glossary, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update the canonical glossary inline

When a term is resolved, update the selected canonical glossary right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

Keep new glossary entries focused on domain language; record implementation decisions in the project's ADRs/specs. An existing `CONTEXT.md` may serve a broader project purpose: preserve that content and follow the project's actual glossary location rather than deleting non-glossary material to impose this collection's format.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).
