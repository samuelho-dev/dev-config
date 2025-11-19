#!/bin/bash
# Auto-load AI credentials from 1Password
# Called by direnv (.envrc) or Nix devShell shellHook
#
# Usage:
#   source scripts/load-ai-credentials.sh
#
# Prerequisites:
#   - 1Password CLI (op) installed
#   - Authenticated: op signin
#   - "Dev" vault with "ai" item containing API keys

# Suppress errors if not authenticated (graceful degradation)
if ! op account get &>/dev/null 2>&1; then
  return 0  # Exit silently, don't break shell initialization
fi

echo "🔐 Loading AI credentials from 1Password..."

# Fetch credentials using op read (recommended 2025 method)
# Format: op://Vault/Item/Field

# Anthropic (Claude)
if [ -z "$ANTHROPIC_API_KEY" ]; then
  ANTHROPIC_API_KEY=$(op read "op://Dev/ai/ANTHROPIC_API_KEY" 2>/dev/null)
  if [ -n "$ANTHROPIC_API_KEY" ]; then
    export ANTHROPIC_API_KEY
    echo "  ✓ Loaded: ANTHROPIC_API_KEY"
  fi
fi

# OpenAI (GPT models)
if [ -z "$OPENAI_API_KEY" ]; then
  OPENAI_API_KEY=$(op read "op://Dev/ai/OPENAI_API_KEY" 2>/dev/null)
  if [ -n "$OPENAI_API_KEY" ]; then
    export OPENAI_API_KEY
    echo "  ✓ Loaded: OPENAI_API_KEY"
  fi
fi

# Google AI (Gemini)
if [ -z "$GOOGLE_AI_API_KEY" ]; then
  GOOGLE_AI_API_KEY=$(op read "op://Dev/ai/GOOGLE_AI_API_KEY" 2>/dev/null)
  if [ -n "$GOOGLE_AI_API_KEY" ]; then
    export GOOGLE_AI_API_KEY
    echo "  ✓ Loaded: GOOGLE_AI_API_KEY"
  fi
fi

# LiteLLM Proxy (for cluster integration)
if [ -z "$LITELLM_MASTER_KEY" ]; then
  LITELLM_MASTER_KEY=$(op read "op://Dev/litellm/MASTER_KEY" 2>/dev/null)
  if [ -n "$LITELLM_MASTER_KEY" ]; then
    export LITELLM_MASTER_KEY
    echo "  ✓ Loaded: LITELLM_MASTER_KEY"
  fi
fi

# Optional: Additional providers
# Uncomment and add to your 1Password "ai" item as needed

# if [ -z "$COHERE_API_KEY" ]; then
#   COHERE_API_KEY=$(op read "op://Dev/ai/COHERE_API_KEY" 2>/dev/null)
#   [ -n "$COHERE_API_KEY" ] && export COHERE_API_KEY && echo "  ✓ Loaded: COHERE_API_KEY"
# fi

# if [ -z "$HUGGINGFACE_TOKEN" ]; then
#   HUGGINGFACE_TOKEN=$(op read "op://Dev/ai/HUGGINGFACE_TOKEN" 2>/dev/null)
#   [ -n "$HUGGINGFACE_TOKEN" ] && export HUGGINGFACE_TOKEN && echo "  ✓ Loaded: HUGGINGFACE_TOKEN"
# fi

echo "✅ AI credentials loaded from 1Password"

# Optional: Create wrapper aliases for OpenCode with auto-injected credentials
alias opencode-with-1p='op run -- opencode'
