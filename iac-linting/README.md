# Infrastructure-as-Code Linting

Security-focused linting for Kubernetes, Docker, Terraform, and GitHub Actions.

## Quick Start

```bash
# Lint Kubernetes manifests
kube-linter lint k8s/ --config iac-linting/.kube-linter.yaml

# Lint Dockerfiles
hadolint Dockerfile --config iac-linting/.hadolint.yaml

# Lint Terraform
tflint --config iac-linting/.tflint.hcl

# Lint GitHub Actions
actionlint -config-file iac-linting/.actionlint.yaml
```

## Available Configurations

| Config | Tool | What It Lints |
|--------|------|---------------|
| `.kube-linter.yaml` | kube-linter | Kubernetes manifests |
| `.hadolint.yaml` | hadolint | Dockerfiles |
| `.tflint.hcl` | tflint | Terraform configs |
| `.actionlint.yaml` | actionlint | GitHub Actions workflows |

## Key Rules Enforced

### Kubernetes (.kube-linter.yaml)

| Rule | Purpose |
|------|---------|
| `no-latest-tag` | Prevent `:latest` image tags |
| `resource-requirements` | Require CPU/memory limits |
| `run-as-non-root` | Enforce non-root containers |
| `read-only-root-fs` | Require read-only filesystem |
| `no-privileged-containers` | Prevent privileged mode |
| `drop-capabilities` | Require capability dropping |

### Dockerfile (.hadolint.yaml)

| Rule | Purpose |
|------|---------|
| `DL3006` | Pin base image versions |
| `DL3007` | Avoid `:latest` tag |
| `DL3008` | Pin apt package versions |
| `DL3025` | Use JSON form for CMD |
| `DL3002` | Avoid root user |

### Terraform (.tflint.hcl)

| Rule | Purpose |
|------|---------|
| `terraform_naming_convention` | Enforce snake_case |
| `terraform_documented_variables` | Require descriptions |
| `terraform_documented_outputs` | Require descriptions |
| `terraform_typed_variables` | Require type definitions |

### GitHub Actions (.actionlint.yaml)

| Check | Purpose |
|-------|---------|
| Shell script validation | Shellcheck integration |
| Action version checks | Validate action references |
| Expression validation | Check GitHub expressions |
| Job dependencies | Validate `needs` references |

## Usage Examples

### CI Pipeline Integration

```yaml
# .github/workflows/lint.yml
name: Lint Infrastructure

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Lint Kubernetes
        uses: stackrox/kube-linter-action@v1
        with:
          directory: k8s/
          config: iac-linting/.kube-linter.yaml

      - name: Lint Dockerfiles
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
          config: iac-linting/.hadolint.yaml

      - name: Lint Terraform
        uses: terraform-linters/setup-tflint@v4
      - run: tflint --config iac-linting/.tflint.hcl
```

### Pre-commit Integration

```yaml
# .pre-commit-config.yaml
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

  - repo: https://github.com/rhysd/actionlint
    rev: v1.6.26
    hooks:
      - id: actionlint
```

### Project-Specific Overrides

Extend configs for project-specific needs:

```yaml
# .hadolint.yaml (project root)
extends: ~/.config/iac-linting/.hadolint.yaml
ignored:
  - DL3008  # Allow unpinned apt packages in dev
```

## Fixing Common Issues

### Missing Resource Limits (Kubernetes)

```yaml
# Wrong - no limits
spec:
  containers:
    - name: app
      image: myapp:1.0.0

# Correct
spec:
  containers:
    - name: app
      image: myapp:1.0.0
      resources:
        limits:
          cpu: "500m"
          memory: "512Mi"
        requests:
          cpu: "100m"
          memory: "128Mi"
```

### Unpinned Base Image (Docker)

```dockerfile
# Wrong
FROM node:latest

# Correct
FROM node:20.10.0-alpine
```

### Missing Variable Description (Terraform)

```hcl
# Wrong
variable "region" {
  type = string
}

# Correct
variable "region" {
  type        = string
  description = "AWS region for resource deployment"
}
```

### Naming Convention (Terraform)

```hcl
# Wrong - camelCase
variable "myVariable" {}

# Correct - snake_case
variable "my_variable" {}
```

## Installation

### macOS (Homebrew)

```bash
brew install kube-linter hadolint tflint actionlint
```

### Linux

```bash
# kube-linter
curl -LO https://github.com/stackrox/kube-linter/releases/download/v0.6.5/kube-linter-linux.tar.gz
tar xzf kube-linter-linux.tar.gz
sudo mv kube-linter /usr/local/bin/

# hadolint
wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# actionlint
go install github.com/rhysd/actionlint/cmd/actionlint@latest
```

### Via Nix (dev-config)

All tools are included in the dev-config flake:

```bash
nix develop  # Activates shell with all linting tools
```

## File Structure

```
iac-linting/
+-- .kube-linter.yaml   # Kubernetes manifest validation
+-- .hadolint.yaml      # Dockerfile linting
+-- .tflint.hcl         # Terraform validation
+-- .actionlint.yaml    # GitHub Actions workflow linting
+-- CLAUDE.md           # Architecture documentation
+-- README.md           # This file
```

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Architecture details and rule reference
- [Biome Configuration](../biome/README.md) - TypeScript/JavaScript linting
- [Strict Linting Guide](../docs/nix/11-strict-linting-guide.md) - Comprehensive guide
- [kube-linter docs](https://github.com/stackrox/kube-linter)
- [hadolint docs](https://github.com/hadolint/hadolint)
- [tflint docs](https://github.com/terraform-linters/tflint)
- [actionlint docs](https://github.com/rhysd/actionlint)
