# Repository Guidelines

## Project Structure & Module Organization
`flake.nix` and `home.nix` compose the base Home Manager system; reusable modules live in `modules/`, while `pkgs/` captures custom packages. App-specific configs sit in `nvim/`, `tmux/`, `ghostty/`, and `zsh/`, each mirroring the target dotfiles. Platform docs reside in `docs/`, automation scripts go in `scripts/`, and reusable templates land in `templates/`. Keep TypeScript utilities under `biome/`, with tests in `.opencode/test/`. Secrets belong in `secrets/` or `secrets.nix.example`—never commit real credentials.

## Build, Test, and Development Commands
Run `nix flake check` after touching the flake to guarantee syntax soundness, and `nix fmt` before commits to apply alejandra formatting. Use `home-manager build --flake .` for dry runs, then `home-manager switch --flake .` to apply the config locally. For TS utilities inside `biome/`, lint via `biome check .` (or `--write` to auto-fix) and type-check with `bunx tsc --noEmit` from `.opencode/`. Execute repository tests using `bun test` or `bun test test/<name>.test.ts` for a focused run.

## Coding Style & Naming Conventions
Nix modules must declare parameters alphabetically (`{ config, lib, pkgs, inputs, ... }`), avoid `with lib;`, and express options via `lib.mkEnableOption` plus conditional logic with `lib.mkIf`. Use two spaces per indent and keep derivations reproducible. In TypeScript, prefer single quotes, semicolons, trailing commas, and `import type` for purely typed imports; never rely on `any` outside of `bun:test`. Export named symbols, keep filenames kebab-case, and model directories after their feature (e.g., `biome/src/git-hooks/`).

## Testing Guidelines
Test files should mirror the folder under test (`biome/test/templates.test.ts`) and rely on `bun:test` describe/test/expect helpers. New features require at least a smoke test that exercises rendered templates or generated configs. When modifying Nix logic, verify real machines with `home-manager build` output plus targeted module activation tests; document manual validation steps in PRs if automated tests are impractical.

## Commit & Pull Request Guidelines
Commits use short, imperative subjects (`nvim: refresh completion defaults`) and describe rationale in the body when touching multiple systems. Squash noisy WIP commits before opening PRs. Every PR must include: a summary of the change, verification steps (`nix flake check`, `bun test`, etc.), screenshots for UI-facing tweaks (e.g., Ghostty themes), and links to any tracking issues. Label PRs with the primary domain (nvim, tmux, nix, tooling) to streamline reviews.

## Security & Configuration Tips
Store machine-specific tokens in `secrets/` and reference them through `age`-encrypted files or environment variables—never inline values in tracked Nix files. Review `user.nix.example` when onboarding new hosts to ensure consistent options, and prefer templated helpers over ad-hoc shell commands to avoid drift between platforms.
