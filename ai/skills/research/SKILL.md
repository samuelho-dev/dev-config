---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

If the user/project authorizes delegation, use a **background research subagent** through the current host's supported tools, following the installed host contract and available tools. If delegation is unavailable, do the research directly and say so.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it where the repo already keeps such notes, within granted write scope. For a native Pi child, bind the required output artifact using the host's output parameter; a filename in task text alone does not route output. The parent verifies the completed cited artifact before placing it in the repo when that write is authorized. A launch receipt is not finished research.
