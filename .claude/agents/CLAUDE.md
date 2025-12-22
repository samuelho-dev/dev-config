---
scope: .claude/agents/
updated: 2025-12-21
relates_to:
  - ../../CLAUDE.md
  - ./.meta/template-standard.md
  - ./.meta/agent-patterns.md
---

# CLAUDE.md

Architectural guidance for Claude Code when working with agent definitions.

## Purpose

This directory contains **42+ specialized agent definitions** for the oh-my-opencode multi-agent AI orchestration system. Each agent is a markdown file that defines expertise, capabilities, model routing, and example usage patterns.

## Architecture Overview

Agents follow a declarative pattern where YAML frontmatter defines metadata and the markdown body defines the agent's persona, skills, and instructions.

```
.claude/agents/
+-- CLAUDE.md                    # This file
+-- .meta/                       # Meta-documentation and templates
|   +-- template-standard.md     # Standard agent template
|   +-- agent-patterns.md        # Common patterns
|   +-- agent-coordination-protocol.md  # Multi-agent orchestration
|   +-- mcp-integration-template.md     # MCP tool integration
|   +-- model-cost-analysis.md   # Model selection criteria
|   +-- agent-audit.md           # Audit checklist
+-- backend-architect.md         # Backend system design
+-- frontend-ui-ux-engineer.md   # UI/UX implementation
+-- typescript-type-safety-expert.md  # TypeScript patterns
+-- effect-architecture-specialist.md # Effect-TS patterns
+-- ... (42+ total agents)
```

## File Structure

### Agent Definition Format

```yaml
---
name: agent-name
description: |
  When to use this agent (triggers, examples).
  Use PROACTIVELY for [domain].
model: opus | sonnet | grok | gemini
---

# Agent persona and expertise description

<role>
Core responsibilities and expertise areas
</role>

<skills>
- Specific technical skills
- Tool proficiencies
- Domain knowledge
</skills>

<constraints>
- What the agent should NOT do
- Boundaries and limitations
</constraints>
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| YAML frontmatter | Top of each .md | Agent metadata and triggers |
| Model routing | `model:` field | Select appropriate LLM |
| Example blocks | `<example>` tags | Usage scenarios |
| Role definition | `<role>` tag | Core expertise declaration |
| Proactive triggers | `description:` | When to auto-invoke |

## Agent Categories

### Architecture & Design
| Agent | Purpose | Model |
|-------|---------|-------|
| `backend-architect` | Backend systems, APIs, microservices | opus |
| `frontend-ui-ux-engineer` | Visual UI/UX implementation | gemini |
| `effect-architecture-specialist` | Effect-TS patterns | opus |
| `ai-architecture-specialist` | AI/ML system design | opus |

### Language Specialists
| Agent | Purpose | Model |
|-------|---------|-------|
| `typescript-type-safety-expert` | TypeScript patterns, type safety | opus |
| `typescript-pro` | Advanced TS features | sonnet |
| `python-pro` | Python best practices | sonnet |
| `javascript-pro` | JS optimization | sonnet |

### Infrastructure & DevOps
| Agent | Purpose | Model |
|-------|---------|-------|
| `k8s-infrastructure-expert` | Kubernetes operations | opus |
| `argocd-gitops-expert` | GitOps workflows | opus |
| `devops-engineer` | CI/CD pipelines | opus |
| `nix-devops-architect` | Nix flakes, Home Manager | opus |

### Database & Data
| Agent | Purpose | Model |
|-------|---------|-------|
| `prisma-expert` | Prisma ORM, migrations | opus |
| `kysely-query-architect` | Type-safe SQL queries | opus |

### Documentation & Quality
| Agent | Purpose | Model |
|-------|---------|-------|
| `document-writer` | Technical documentation | gemini |
| `code-reviewer` | Code quality analysis | opus |
| `api-documenter` | API documentation | opus |

### Debugging & Performance
| Agent | Purpose | Model |
|-------|---------|-------|
| `debugger` | Error analysis | opus |
| `error-detective` | Log analysis | opus |
| `performance-engineer` | Performance optimization | opus |

## Adding New Agents

1. **Copy template:**
   ```bash
   cp .meta/template-standard.md new-agent-name.md
   ```

2. **Define frontmatter:**
   - `name`: kebab-case identifier
   - `description`: Usage triggers with examples
   - `model`: opus (complex) | sonnet (balanced) | grok (fast) | gemini (creative)

3. **Write persona:**
   - Clear role definition
   - Specific skills list
   - Constraints and boundaries

4. **Add examples:**
   - Real usage scenarios
   - Expected behavior
   - Commentary for context

5. **Test with orchestrator:**
   - Verify routing works
   - Check example triggers fire correctly

## Model Selection Guide

| Model | Use When | Cost |
|-------|----------|------|
| `opus` | Complex architecture, critical decisions | $$$ |
| `sonnet` | Balanced tasks, code generation | $$ |
| `grok` | Fast searches, simple queries | $ |
| `gemini` | Creative tasks, UI/UX | $$ |

## Integration with OpenCode

Agents are loaded by the oh-my-opencode orchestration system:

```nix
# In home.nix
dev-config.opencode.ohMyOpencode = {
  enable = true;
  # Agents loaded from .claude/agents/
};
```

**Invocation:**
```
@backend-architect Design API for user service
@frontend-ui-ux-engineer Create responsive navbar
@debugger Analyze this error trace
```

## For Future Claude Code Instances

When modifying agents:

- [ ] **Follow template** in `.meta/template-standard.md`
- [ ] **Include examples** with `<example>` tags for each usage pattern
- [ ] **Set correct model** - use opus sparingly (expensive)
- [ ] **Define clear triggers** in description for proactive invocation
- [ ] **Add constraints** to prevent scope creep
- [ ] **Update this CLAUDE.md** when adding new agent categories
- [ ] **Coordinate with orchestrator** - check `.opencode/` integration
- [ ] **Test routing** before committing new agents
- [ ] **Document proactive triggers** - when should agent auto-fire?
- [ ] **Keep names descriptive** - kebab-case, domain-focused
