-- Debug script to test TypeScript return type stripper
-- Run with: nvim --headless -c "luafile debug-ts-stripper.lua" test-simple.ts

-- Enable debug mode
local stripper = require 'plugins.custom.typescript-return-stripper'
stripper.config.debug = true

print("=== TypeScript Return Type Stripper Debug ===\n")

-- Test parser availability
print("1. Testing parser availability...")
local has_ts = stripper.has_parser('typescript')
print(string.format("   TypeScript parser: %s\n", has_ts and "✅ Available" or "❌ Missing"))

if not has_ts then
  print("ERROR: TypeScript parser not installed!")
  print("Install with: :TSInstall typescript")
  os.exit(1)
end

-- Test query
print("2. Testing tree-sitter query...")
stripper.test_query(0)
print()

-- Find return types
print("3. Finding return types...")
local matches = stripper.find_return_types(0)
print(string.format("   Found %d return type annotations\n", #matches))

-- Preview changes
print("4. Preview of what would be removed...")
stripper.preview_changes(0)
print()

-- Test actual stripping (dry run)
print("5. Testing strip operation (dry run)...")
stripper.config.dry_run = true
local count = stripper.strip_return_types(0)
print(string.format("   Would remove %d annotations\n", count))

print("=== Debug Complete ===")
