import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "Validate Nix configuration syntax and structure",
  args: {
    path: tool.schema.string().optional().describe("Path to Nix file or directory (defaults to current directory)"),
    strict: tool.schema.boolean().optional().describe("Enable strict validation mode")
  },
  async execute(args, context) {
    const { path = ".", strict = false } = args

    try {
      // Validate Nix syntax
      const syntaxCheck = await Bun.$`nix-instantiate --eval --strict ${path} 2>&1`.text()

      // Check for common issues
      const issues = []

      if (syntaxCheck.includes("error:")) {
        issues.push("Syntax errors found")
      }

      if (strict) {
        // Additional strict checks
        const libCheck = await Bun.$`grep -r "with lib;" ${path} 2>/dev/null || true`.text()
        if (libCheck) {
          issues.push("Found 'with lib;' usage - should use explicit lib. prefixes")
        }

        const secretCheck = await Bun.$`grep -r "password\\|secret\\|key" ${path} --include="*.nix" 2>/dev/null | grep -v "sops-" || true`.text()
        if (secretCheck) {
          issues.push("Potential hardcoded secrets found - use sops-nix instead")
        }
      }

      return {
        success: issues.length === 0,
        syntaxOutput: syntaxCheck,
        issues: issues,
        recommendations: issues.length > 0 ? [
          "Run 'nix fmt' to fix formatting issues",
          "Use explicit lib. prefixes instead of 'with lib;'",
          "Store secrets in sops-nix encrypted files"
        ] : []
      }
    } catch (error) {
      return {
        success: false,
        error: error.message,
        recommendations: ["Check Nix installation and file paths"]
      }
    }
  }
})
