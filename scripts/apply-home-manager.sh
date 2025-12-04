#!/usr/bin/env bash
# Apply Home Manager configuration (ensures user.nix is Git-staged)
set -euo pipefail

# Change to repository root
cd "$(dirname "$0")/.."

# Check if user.nix exists
if [ ! -f user.nix ]; then
  echo "❌ user.nix not found."
  echo ""
  echo "Create it from the template:"
  echo "  cp user.nix.example user.nix"
  echo ""
  echo "Then edit user.nix with your username and home directory:"
  echo "  {"
  echo "    username = \"your-username\";"
  echo "    homeDirectory = \"/Users/your-username\";  # macOS"
  echo "  }"
  echo ""
  echo "Finally, stage it for Nix visibility:"
  echo "  git add -f user.nix"
  exit 1
fi

# Check if user.nix is staged in Git
if ! git ls-files --error-unmatch user.nix &>/dev/null; then
  echo "⚠️  user.nix exists but is not staged in Git."
  echo ""
  echo "Nix flakes require files to be Git-tracked for evaluation."
  echo "Staging user.nix now with git add -f..."
  git add -f user.nix
  echo "✅ user.nix staged (gitignored, won't be committed)"
  echo ""
fi

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ "$(uname -m)" == "arm64" ]]; then
    FLAKE_CONFIG="aarch64-darwin"
  else
    FLAKE_CONFIG="x86_64-darwin"
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [[ "$(uname -m)" == "x86_64" ]]; then
    FLAKE_CONFIG="x86_64-linux"
  else
    echo "❌ Unsupported Linux architecture: $(uname -m)"
    exit 1
  fi
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

echo "🏠 Applying Home Manager configuration for $FLAKE_CONFIG..."
echo ""

# Apply Home Manager
# user.nix is staged in Git (visible to Nix) but gitignored (won't commit)
home-manager switch --flake ".#$FLAKE_CONFIG"

echo ""
echo "✅ Home Manager configuration applied successfully!"
echo ""
echo "Changes take effect in new terminal windows."
