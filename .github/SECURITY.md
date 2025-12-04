# Security Policy

## Overview

This repository is **PUBLIC** and contains GitHub Actions workflows that use **GitHub Secrets** to access:
- Backblaze B2 storage (binary cache)
- Nix package signing keys
- GitHub Container Registry

## Security Model

### ✅ Protections in Place

1. **Conditional Secret Access**
   - Secrets are ONLY accessible on pushes to `main` branch
   - Pull requests do NOT have access to secrets
   - Workflow conditions prevent secret exposure

2. **CODEOWNERS Protection**
   - Workflow files require @samuelho-dev approval
   - Prevents accidental secret exposure through workflow modifications
   - Applies to `.github/workflows/`, flake files, and security docs

3. **Secret Hygiene**
   - Signing keys are shredded (`shred -u`) immediately after use
   - No secrets logged or persisted on runners
   - Environment variables cleared after workflow execution

4. **Fork PR Approval Required**
   - External contributors cannot trigger workflows without approval
   - Configured via: Settings → Actions → General → Fork pull request workflows

### 🔐 GitHub Secrets

| Secret Name | Purpose | Scope |
|-------------|---------|-------|
| `B2_ACCESS_KEY_ID` | B2 S3 API access key ID | Write access to `ai-dev-env/nix/cache` only |
| `B2_SECRET_ACCESS_KEY` | B2 S3 API secret key | Write access to `ai-dev-env/nix/cache` only |
| `NIX_SIGNING_KEY` | Nix cache signing key | Signs packages pushed to B2 cache |

**Source**: All secrets stored in 1Password (Dev vault → backblaze item)

## Personal Use Policy

**This is a personal repository** maintained solely by @samuelho-dev:
- ❌ No external contributors accepted
- ❌ Fork PRs will not be approved
- ✅ Workflow modifications require explicit commit
- ✅ CODEOWNERS provides review prompt for sensitive files

## Workflow Security

### Build and Cache Workflow (`build-devpod-image.yaml`)

**Triggers**:
- ✅ Push to `main` (secrets accessible)
- ✅ Pull requests (secrets NOT accessible)
- ✅ Manual dispatch (secrets accessible if on main)

**Secret Access Conditions**:
```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main' && inputs.skip_cache_push != 'true'
```

**Security Features**:
- Secrets only used for B2 push step (not build)
- Signing key written to `/tmp/cache-priv-key.pem`, used once, then shredded
- AWS credentials injected as environment variables (not logged)
- Docker image pushed to GHCR (public registry, no secrets)

## Incident Response

### If Secrets Are Compromised

1. **Immediately Revoke**:
   ```bash
   # Revoke B2 application key via 1Password or B2 web console
   # Rotate Nix signing key (generate new keypair)
   ```

2. **Remove from GitHub**:
   ```bash
   gh secret delete B2_ACCESS_KEY_ID
   gh secret delete B2_SECRET_ACCESS_KEY
   gh secret delete NIX_SIGNING_KEY
   ```

3. **Audit Cache**:
   ```bash
   # Check for unauthorized packages in B2
   b2 ls b2://ai-dev-env/nix/cache/
   ```

4. **Regenerate**:
   - Generate new B2 application key
   - Generate new Nix signing keypair
   - Update 1Password
   - Re-add secrets to GitHub

### If Malicious PR Merged

1. **Revert commit**:
   ```bash
   git revert <commit-sha>
   git push origin main --force
   ```

2. **Check workflow runs**:
   ```bash
   gh run list --limit 20
   ```

3. **Audit B2 cache for unauthorized uploads**

## Reporting Security Issues

**Contact**: @samuelho-dev via GitHub Issues (mark as security-related)

**Do NOT** create public issues for security vulnerabilities. Use GitHub's private security advisory feature:
- Repository → Security → Advisories → New draft security advisory

## Security Best Practices

1. **Never commit secrets to git** (use GitHub Secrets or 1Password)
2. **Review all workflow changes** before committing (CODEOWNERS helps)
3. **Monitor Actions runs** for unexpected executions
4. **Audit B2 cache** periodically for unauthorized packages
5. **Rotate secrets** every 90 days (B2 keys, Nix signing key)

## Public Repository Considerations

**Why Public?**
- Showcase Nix expertise
- Share dev-config patterns with community
- Transparent infrastructure-as-code

**Why Not Private?**
- Personal project (no collaborators)
- Proper secret conditioning in workflows
- Educational value for others

**Future Consideration**: If this becomes a team project with multiple contributors, consider:
- Making repository private
- Using GitHub Environments with required reviewers
- Implementing branch protection rules

---

**Last Updated**: 2025-12-04
**Maintained By**: @samuelho-dev
