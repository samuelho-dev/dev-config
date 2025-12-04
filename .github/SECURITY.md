# Security Policy

## Repository Configuration

- **Visibility**: Public
- **Maintainer**: @samuelho-dev (solo)
- **Contributions**: Not accepted

## GitHub Secrets

| Secret | Purpose | Permissions |
|--------|---------|-------------|
| `B2_ACCESS_KEY_ID` | B2 S3 API access | Write: `ai-dev-env/nix/cache` |
| `B2_SECRET_ACCESS_KEY` | B2 S3 API secret | Write: `ai-dev-env/nix/cache` |
| `NIX_SIGNING_KEY` | Package signing | Sign: Nix store paths |

**Source**: 1Password (Dev/backblaze)

## Protection Mechanisms

### Workflow Secret Access
Secrets accessible only when:
```yaml
github.event_name == 'push'
  && github.ref == 'refs/heads/main'
  && inputs.skip_cache_push != 'true'
```

### File Protection
- **CODEOWNERS**: Workflow files require approval
- **Fork PR Approval**: External workflows blocked
- **Secret Hygiene**: Keys shredded after use (`shred -u`)

## Incident Response

### Compromised Secrets
1. Revoke B2 key via 1Password/B2 console
2. Generate new Nix signing keypair
3. Delete GitHub secrets: `gh secret delete <name>`
4. Update 1Password with new credentials
5. Re-add secrets to GitHub

### Malicious Commit
1. Revert: `git revert <sha> && git push --force`
2. Audit: `gh run list --limit 20`
3. Check B2 for unauthorized uploads

## Maintenance

- **Secret Rotation**: Every 90 days
- **Audit Frequency**: Monthly B2 cache review
- **Contact**: @samuelho-dev via GitHub Issues

---
Last updated: 2025-12-04
