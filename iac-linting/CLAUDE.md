---
scope: iac-linting/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../biome/CLAUDE.md
validation:
  max_days_stale: 30
---

# Infrastructure-as-Code Linting

Architectural guidance for IaC linting configurations.

## Purpose

This directory provides opinionated linting configurations for infrastructure-as-code tools: Kubernetes manifests, Dockerfiles, Terraform, and GitHub Actions. These configs enforce security best practices and consistency across infrastructure definitions.

## Architecture Overview

Each linter has its own configuration file following tool-specific formats. Configs are designed to be strict by default, catching common security issues and enforcing best practices that are often overlooked.

Key principles:
- **Security-first**: Resource limits, non-root users, version pinning
- **Explicit over implicit**: Require documentation, explicit values
- **Consistency**: Naming conventions, structure patterns

## File Structure

```
iac-linting/
+-- .kube-linter.yaml   # Kubernetes manifest validation
+-- .hadolint.yaml      # Dockerfile linting
+-- .tflint.hcl         # Terraform validation
+-- .actionlint.yaml    # GitHub Actions workflow linting
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Resource limits | .kube-linter.yaml | Require CPU/memory limits on containers |
| Non-root users | .hadolint.yaml | Enforce USER directive in Dockerfiles |
| Version pinning | .hadolint.yaml | Pin base image versions |
| Variable docs | .tflint.hcl | Require variable descriptions |
| Snake case | .tflint.hcl | Enforce naming conventions |

## Configuration Reference

### .kube-linter.yaml

**Tool:** [kube-linter](https://github.com/stackrox/kube-linter)

**Key checks enabled:**

| Check | Purpose |
|-------|---------|
| `no-latest-tag` | Prevent `:latest` image tags |
| `resource-requirements` | Require CPU/memory limits |
| `run-as-non-root` | Enforce non-root containers |
| `read-only-root-fs` | Require read-only filesystem |
| `no-privileged-containers` | Prevent privileged mode |
| `drop-capabilities` | Require capability dropping |

**Usage:**
```bash
kube-linter lint manifests/ --config iac-linting/.kube-linter.yaml
```

### .hadolint.yaml

**Tool:** [hadolint](https://github.com/hadolint/hadolint)

**Key rules enforced:**

| Rule | Purpose |
|------|---------|
| `DL3006` | Pin base image versions |
| `DL3007` | Avoid `:latest` tag |
| `DL3008` | Pin apt package versions |
| `DL3025` | Use JSON form for CMD |
| `DL3002` | Avoid root user |

**Usage:**
```bash
hadolint Dockerfile --config iac-linting/.hadolint.yaml
```

### .tflint.hcl

**Tool:** [tflint](https://github.com/terraform-linters/tflint)

**Key rules enforced:**

| Rule | Purpose |
|------|---------|
| `terraform_naming_convention` | Enforce snake_case |
| `terraform_documented_variables` | Require descriptions |
| `terraform_documented_outputs` | Require descriptions |
| `terraform_typed_variables` | Require type definitions |

**Usage:**
```bash
tflint --config iac-linting/.tflint.hcl
```

### .actionlint.yaml

**Tool:** [actionlint](https://github.com/rhysd/actionlint)

**Key validations:**

| Check | Purpose |
|-------|---------|
| Shell script validation | Shellcheck integration |
| Action version checks | Validate action references |
| Expression validation | Check GitHub expressions |
| Job dependencies | Validate `needs` references |

**Usage:**
```bash
actionlint -config-file iac-linting/.actionlint.yaml
```

## Adding/Modifying

### Using in CI Pipeline

**GitHub Actions:**
```yaml
- name: Lint Kubernetes
  run: kube-linter lint k8s/ --config iac-linting/.kube-linter.yaml

- name: Lint Dockerfiles
  run: hadolint Dockerfile --config iac-linting/.hadolint.yaml

- name: Lint Terraform
  run: tflint --config iac-linting/.tflint.hcl
```

### Adding New Rules

1. Research rule in tool documentation
2. Add to appropriate config file
3. Test against existing infrastructure
4. Document in this CLAUDE.md

### Creating Project-Specific Overrides

Projects can extend these configs:

```yaml
# .hadolint.yaml (project root)
extends: ~/.config/iac-linting/.hadolint.yaml
ignored:
  - DL3008  # Allow unpinned apt packages in dev
```

## Pre-commit Integration

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
        args: [--config, iac-linting/.hadolint.yaml]

  - repo: https://github.com/terraform-linters/tflint
    rev: v0.50.0
    hooks:
      - id: tflint
        args: [--config, iac-linting/.tflint.hcl]
```

## Common Issues

### kube-linter resource requirements

**Error:** Missing resource limits

**Fix:** Add to container spec:
```yaml
resources:
  limits:
    cpu: "500m"
    memory: "512Mi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

### hadolint version pinning

**Error:** DL3006 - pin version

**Fix:** Use specific version tags:
```dockerfile
# Wrong
FROM node:latest

# Correct
FROM node:20.10.0-alpine
```

### tflint naming convention

**Error:** terraform_naming_convention

**Fix:** Use snake_case:
```hcl
# Wrong
variable "myVariable" {}

# Correct
variable "my_variable" {}
```

## For Future Claude Code Instances

- [ ] Run linters before committing infrastructure changes
- [ ] Use project-specific overrides sparingly
- [ ] Document any rule exceptions with comments
- [ ] Keep configs updated with latest tool versions
- [ ] Test new rules against existing infrastructure before enabling
- [ ] Integrate with pre-commit hooks for automatic validation
