# Testing B2 Cache Workflow

This file is created to test the GitHub Actions workflow with B2 binary cache integration.

## Test Details
- **Date**: 2025-12-04
- **Branch**: test/b2-cache-workflow
- **Purpose**: Verify B2 cache push/pull in CI/CD

## Expected Behavior
1. Workflow triggers on push to this branch
2. Builds DevPod Nix image
3. Does NOT push to B2 or GHCR (PR behavior)
4. Verifies build succeeds
