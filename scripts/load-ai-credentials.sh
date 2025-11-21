#!/usr/bin/env bash
# Load AI credentials from 1Password
# Usage: source scripts/load-ai-credentials.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Loading AI credentials from 1Password...${NC}"

# Check 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo -e "${RED}Error: 1Password CLI (op) not installed${NC}"
    echo "Install: brew install --cask 1password-cli"
    exit 1
fi

# Check authentication
if ! op account list &> /dev/null; then
    echo -e "${RED}Error: Not signed in to 1Password${NC}"
    echo "Run: op signin"
    exit 1
fi

# Load credentials (suppress errors for missing keys)
ANTHROPIC_API_KEY=$(op read "op://Dev/ai/ANTHROPIC_API_KEY" 2>/dev/null || echo "")
export ANTHROPIC_API_KEY
OPENAI_API_KEY=$(op read "op://Dev/ai/OPENAI_API_KEY" 2>/dev/null || echo "")
export OPENAI_API_KEY
GOOGLE_AI_API_KEY=$(op read "op://Dev/ai/GOOGLE_AI_API_KEY" 2>/dev/null || echo "")
export GOOGLE_AI_API_KEY
LITELLM_MASTER_KEY=$(op read "op://Dev/ai/LITELLM_MASTER_KEY" 2>/dev/null || echo "")
export LITELLM_MASTER_KEY

# Report loaded credentials
echo -e "${GREEN}✓ AI credentials loaded:${NC}"
[ -n "$ANTHROPIC_API_KEY" ] && echo "  • ANTHROPIC_API_KEY (${#ANTHROPIC_API_KEY} chars)"
[ -n "$OPENAI_API_KEY" ] && echo "  • OPENAI_API_KEY (${#OPENAI_API_KEY} chars)"
[ -n "$GOOGLE_AI_API_KEY" ] && echo "  • GOOGLE_AI_API_KEY (${#GOOGLE_AI_API_KEY} chars)"
[ -n "$LITELLM_MASTER_KEY" ] && echo "  • LITELLM_MASTER_KEY (${#LITELLM_MASTER_KEY} chars)"

# Warn about missing credentials
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ] && [ -z "$GOOGLE_AI_API_KEY" ]; then
    echo -e "${YELLOW}Warning: No AI API keys loaded from 1Password${NC}"
    echo "  Check that keys exist in 1Password vault: Dev/ai"
fi
