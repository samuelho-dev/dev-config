# TFLint Configuration
# Strict Terraform linting with recommended presets
# https://github.com/terraform-linters/tflint

config {
  # Recursively check modules
  module = true

  # Don't fail on warnings during development
  force = false

  # Plugin directory (defaults to ~/.tflint.d/plugins)
  # plugin_dir = ".tflint.d/plugins"
}

# Enable the Terraform language plugin
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Naming convention - enforce snake_case
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Require documented variables
rule "terraform_documented_variables" {
  enabled = true
}

# Require documented outputs
rule "terraform_documented_outputs" {
  enabled = true
}

# Require type declarations for variables
rule "terraform_typed_variables" {
  enabled = true
}

# Standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Workspace naming
rule "terraform_workspace_remote" {
  enabled = true
}

# Prevent deprecated syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

# Comment style
rule "terraform_comment_syntax" {
  enabled = true
}

# Empty blocks
rule "terraform_empty_list_equality" {
  enabled = true
}

# Required version constraint
rule "terraform_required_version" {
  enabled = true
}

# Required providers
rule "terraform_required_providers" {
  enabled = true
}

# Unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Module source best practices
rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}
