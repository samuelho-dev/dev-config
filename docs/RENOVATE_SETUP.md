# Renovate Bot Setup for dev-config

This guide explains how to configure your self-hosted Renovate bot to automatically update dependencies in the dev-config repository.

## Overview

Renovate will automatically update:
- **Nix packages** (flake.lock) - Weekly updates
- **Pre-commit hooks** (.pre-commit-config.yaml) - Auto-merge patch, manual review major/minor
- **GitHub Actions** (.github/workflows/*.yml) - Auto-merge patch, manual review major/minor
- **Security vulnerabilities** - Immediate, high priority

## Self-Hosted Renovate Configuration

### 1. Renovate Bot Deployment (In Your Cluster)

Your Renovate bot should have these configurations:

**Kubernetes ConfigMap/Secret:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: renovate-config
  namespace: renovate
data:
  config.js: |
    module.exports = {
      platform: 'github',
      endpoint: 'https://api.github.com/',
      token: process.env.GITHUB_TOKEN,  // GitHub PAT with repo access
      repositories: [
        'samuelho-dev/dev-config'
      ],
      autodiscover: false,  // Explicit repo list
      onboarding: false,    // Skip onboarding PR (renovate.json already exists)
      requireConfig: 'required',  // Use renovate.json in repo
      gitAuthor: 'Renovate Bot <bot@renovateapp.com>',

      // Nix support
      binarySource: 'install',  // Required for Nix manager

      // Performance
      persistRepoData: true,
      repositoryCache: 'enabled',

      // Logging
      logLevel: 'info',
      logContext: 'renovate/dev-config'
    };
```

**Required GitHub Token Permissions:**
- `repo` - Full repository access
- `workflow` - Update GitHub Actions workflows
- `read:org` - Read organization data (if private repo)

### 2. Enable Renovate for This Repository

**Option A: Add to Renovate Bot's Repository List**

If your bot uses a static list:
```javascript
// renovate-bot config.js
repositories: [
  'samuelho-dev/ai-dev-env',
  'samuelho-dev/dev-config'  // Add this line
]
```

**Option B: Use Autodiscover with Filters**

If your bot uses autodiscover:
```javascript
module.exports = {
  autodiscover: true,
  autodiscoverFilter: [
    'samuelho-dev/*'  // Discover all repos in org
  ]
};
```

### 3. Verify Renovate Configuration

**Test the renovate.json syntax:**
```bash
# Install Renovate CLI (if not installed)
npm install -g renovate

# Validate configuration
renovate-config-validator

# Dry-run (test without creating PRs)
RENOVATE_TOKEN=ghp_xxx renovate --dry-run samuelho-dev/dev-config
```

**Expected output:**
```
INFO: Repository started
INFO: Dependency extraction complete
INFO: Detected package files:
  - flake.lock (nix)
  - .pre-commit-config.yaml (pre-commit)
  - .github/workflows/*.yml (github-actions)
INFO: Found 15+ dependencies
INFO: PRs to create: 3
  - Update flake.lock
  - Update pre-commit hooks (alejandra, shellcheck)
  - Update GitHub Actions (actions/checkout)
```

### 4. Configure Renovate Bot Schedule

**CronJob in Kubernetes:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: renovate
  namespace: renovate
spec:
  # Run every 3 hours during work week, every hour on weekends
  schedule: "0 */3 * * 1-5"  # Weekdays every 3 hours
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: renovate
            image: renovate/renovate:latest
            env:
            - name: RENOVATE_CONFIG_FILE
              value: /config/config.js
            - name: GITHUB_TOKEN
              valueFrom:
                secretKeyRef:
                  name: renovate-secrets
                  key: github-token
            volumeMounts:
            - name: config
              mountPath: /config
          volumes:
          - name: config
            configMap:
              name: renovate-config
          restartPolicy: Never
```

## Repository-Specific Configuration (renovate.json)

The `renovate.json` in this repo defines:

### Update Schedules

| Component | Schedule | Auto-merge | Review |
|-----------|----------|------------|--------|
| Nix flake.lock | Every weekend | No | Manual |
| Pre-commit (patch) | Immediate | Yes | None |
| Pre-commit (major/minor) | Immediate | No | Manual |
| GitHub Actions (patch) | Immediate | Yes | None |
| GitHub Actions (major/minor) | Immediate | No | Manual |
| Security updates | Immediate | Yes | None |

### Auto-Merge Rules

**Safe for auto-merge:**
- Patch updates (1.2.3 → 1.2.4)
- Pre-commit hook patches
- GitHub Actions patches
- Security vulnerabilities

**Require manual review:**
- Major updates (1.x.x → 2.x.x)
- Minor updates (1.2.x → 1.3.x)
- Nix flake.lock updates
- Breaking changes

### Dependency Dashboard

Renovate creates a GitHub Issue titled "🤖 Dependency Updates Dashboard" that shows:
- ✅ Merged updates
- ⏳ Pending updates
- ❌ Failed updates
- 🔒 Rate-limited updates

**View dashboard:** https://github.com/samuelho-dev/dev-config/issues?q=is:issue+is:open+label:renovate-dashboard

## Testing Updates

### Local Testing (Before Merge)

When Renovate creates a PR, test it locally:

```bash
# Fetch the Renovate PR branch
git fetch origin renovate/nix-packages

# Check out the branch
git checkout renovate/nix-packages

# Test Nix configuration
bash scripts/test-config.sh

# Test Home Manager build
home-manager build --flake .

# Test actual application
home-manager switch --flake . --dry-run

# If successful, merge via GitHub UI
```

### CI/CD Validation

All Renovate PRs automatically trigger:
- Nix flake validation
- Nix formatting check
- Home Manager build test (3 platforms)
- Pre-commit hook validation
- Secret scanning (gitleaks)

**PR must pass all checks before merge.**

## Monitoring Renovate

### Check Renovate Logs (Kubernetes)

```bash
# View recent Renovate runs
kubectl logs -n renovate -l app=renovate --tail=100

# Follow live logs
kubectl logs -n renovate -l app=renovate -f

# Check CronJob history
kubectl get cronjobs -n renovate
kubectl get jobs -n renovate
```

### Expected Log Output

**Successful run:**
```
INFO: Repository started {"repository":"samuelho-dev/dev-config"}
INFO: Dependency extraction complete {"stats":{"managers":{"nix":1,"pre-commit":8,"github-actions":3}}}
INFO: Branches created: 2
  - renovate/nix-packages
  - renovate/pre-commit-hooks
INFO: PRs created: 2
INFO: Repository finished {"durationMs":45000}
```

**No updates needed:**
```
INFO: Repository is up-to-date
INFO: No changes detected
```

## Troubleshooting

### Issue: Renovate Not Creating PRs

**Diagnosis:**
```bash
# Check if bot has access to repo
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/samuelho-dev/dev-config

# Check Renovate logs
kubectl logs -n renovate -l app=renovate | grep ERROR
```

**Common causes:**
- GitHub token expired or missing permissions
- Repository not in Renovate's config
- Rate limit exceeded (GitHub API)
- renovate.json syntax error

**Resolution:**
```bash
# Validate renovate.json
renovate-config-validator

# Test with dry-run
RENOVATE_TOKEN=xxx renovate --dry-run samuelho-dev/dev-config
```

### Issue: Auto-Merge Not Working

**Diagnosis:**
Check PR labels and conditions:
- PR must have `auto-merge` label
- All CI checks must pass
- Branch protection rules met

**Resolution:**
```yaml
# Update renovate.json
{
  "platformAutomerge": true,  # Enable platform auto-merge
  "packageRules": [{
    "automerge": true,
    "automergeType": "pr",     # Use PR auto-merge (not branch)
    "automergeStrategy": "squash"  # Squash commits
  }]
}
```

### Issue: Too Many PRs Created

**Diagnosis:**
Rate limiting not configured properly.

**Resolution:**
```json
{
  "prConcurrentLimit": 5,      # Max 5 PRs open at once
  "prHourlyLimit": 2,          # Max 2 PRs per hour
  "branchConcurrentLimit": 10  # Max 10 branches at once
}
```

### Issue: Nix Updates Failing

**Diagnosis:**
```bash
# Check if Nix manager is enabled
grep -A10 "enabledManagers" renovate.json

# Test flake update locally
nix flake update
git diff flake.lock
```

**Common causes:**
- Nix not installed in Renovate container
- `binarySource` not set to `install`
- flake.lock syntax error

**Resolution:**
```javascript
// Renovate config.js
module.exports = {
  binarySource: 'install',  // Install Nix in container
  docker: {
    image: 'renovate/renovate:latest'  // Use official image with Nix
  }
};
```

## Best Practices

### 1. Review Before Merging

Even with auto-merge enabled:
- Review major/minor updates manually
- Check CHANGELOG/release notes
- Test locally if breaking changes

### 2. Monitor Dependency Dashboard

Weekly review of dashboard:
- Merge safe updates
- Defer risky updates
- Close stale updates

### 3. Keep Renovate Configuration Updated

Quarterly review of renovate.json:
- Adjust schedules based on team capacity
- Update auto-merge rules
- Add new package managers

### 4. Use Stability Days

Wait 3 days before merging new releases:
```json
{
  "stabilityDays": 3,
  "prCreationRestrictions": {
    "minimumReleaseAge": "3 days"
  }
}
```

**Rationale:** Catch critical bugs in new releases before adopting.

## Security Considerations

### GitHub Token Security

**Required permissions (minimal):**
- `repo` - Repository access
- `workflow` - Update workflows

**Best practices:**
- Use GitHub App instead of PAT (if possible)
- Rotate token every 90 days
- Store in Kubernetes Secret (not ConfigMap)
- Use sealed-secrets or external-secrets operator

### Auto-Merge Security

**Safe for auto-merge:**
- Patch updates from trusted sources
- Pre-commit hooks (validated in CI)
- GitHub Actions (official actions only)

**Never auto-merge:**
- Major version updates
- Dependencies from unknown sources
- Updates that modify security-sensitive code

## Integration with CI/CD

### GitHub Actions Workflow

Renovate PRs trigger all existing CI/CD checks:

```yaml
# .github/workflows/renovate-validate.yml
name: Validate Renovate PRs

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    if: startsWith(github.head_ref, 'renovate/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Nix
        uses: cachix/install-nix-action@v24

      - name: Run tests
        run: bash scripts/test-config.sh

      - name: Check for breaking changes
        run: |
          # Fail if major version bump
          git diff origin/main -- flake.lock | grep -q "nixpkgs.*24\.05.*24\.11" && exit 1
          exit 0
```

## Metrics & Reporting

### Track Renovate Effectiveness

**Metrics to monitor:**
- PRs created per week
- PRs merged per week
- Time to merge (median)
- Failed updates (%)
- Security vulnerabilities patched

**Grafana dashboard queries:**
```promql
# PRs created by Renovate
sum(rate(github_pr_created{author="renovate[bot]"}[7d]))

# Time to merge
histogram_quantile(0.5,
  rate(github_pr_merged_duration_seconds{author="renovate[bot]"}[7d])
)
```

## Additional Resources

- **Renovate Docs:** https://docs.renovatebot.com/
- **Nix Manager:** https://docs.renovatebot.com/modules/manager/nix/
- **Self-Hosted Guide:** https://docs.renovatebot.com/self-hosted-configuration/
- **GitHub App Setup:** https://docs.renovatebot.com/modules/platform/github/

## Support

For issues with:
- **Renovate configuration:** Check renovate.json syntax
- **Self-hosted bot:** Check Kubernetes logs
- **GitHub integration:** Verify token permissions
- **Nix updates:** Test locally with `nix flake update`

**Need help?** Create an issue with:
- Renovate logs (sanitize sensitive data)
- renovate.json configuration
- Expected vs actual behavior
