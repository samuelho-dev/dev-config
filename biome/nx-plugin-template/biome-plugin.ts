/**
 * Nx Plugin for Biome
 *
 * Automatically generates Biome targets for packages with biome.json files.
 * Copy this file to your Nx monorepo's tools/ directory and register in nx.json.
 *
 * Generated targets:
 * - biome-check: Run linter and formatter checks (no write)
 * - biome-lint: Run linter only
 * - biome-format: Format code (with write)
 * - biome-ci: CI mode (strict, no write)
 *
 * Usage in nx.json:
 * {
 *   "plugins": [
 *     {
 *       "plugin": "./tools/biome-plugin",
 *       "options": {
 *         "checkTargetName": "biome-check",
 *         "lintTargetName": "biome-lint",
 *         "formatTargetName": "biome-format",
 *         "ciTargetName": "biome-ci"
 *       }
 *     }
 *   ]
 * }
 */

import { existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import {
  type CreateNodesContextV2,
  type CreateNodesV2,
  createNodesFromFiles,
  type TargetConfiguration
} from '@nx/devkit'

export interface BiomePluginOptions {
  /** Target name for combined check (lint + format). Default: "biome-check" */
  checkTargetName?: string
  /** Target name for lint only. Default: "biome-lint" */
  lintTargetName?: string
  /** Target name for format with write. Default: "biome-format" */
  formatTargetName?: string
  /** Target name for CI mode. Default: "biome-ci" */
  ciTargetName?: string
}

export const createNodesV2: CreateNodesV2<BiomePluginOptions> = [
  '**/biome.json',
  async (configFiles, options, context) => {
    return await createNodesFromFiles(
      (configFile, options, context) => createNodesInternal(configFile, options, context),
      configFiles,
      options,
      context
    )
  }
]

function createNodesInternal(
  configFilePath: string,
  options: BiomePluginOptions | undefined,
  context: CreateNodesContextV2
) {
  const root = dirname(configFilePath)

  // Skip root biome.json - only process package-level configs
  if (root === '.') {
    return {}
  }

  // Verify this is a valid package directory
  const hasPackageJson = existsSync(join(context.workspaceRoot, root, 'package.json'))
  const hasProjectJson = existsSync(join(context.workspaceRoot, root, 'project.json'))

  if (!(hasPackageJson || hasProjectJson)) {
    return {}
  }

  const checkTargetName = options?.checkTargetName ?? 'biome-check'
  const lintTargetName = options?.lintTargetName ?? 'biome-lint'
  const formatTargetName = options?.formatTargetName ?? 'biome-format'
  const ciTargetName = options?.ciTargetName ?? 'biome-ci'

  // Input files that affect cache invalidation
  const baseInputs = [
    'default',
    '^default',
    '{workspaceRoot}/biome.json',
    '{projectRoot}/biome.json',
    '{workspaceRoot}/tools/gritql-patterns/**/*.grit',
    {
      externalDependencies: ['@biomejs/biome']
    }
  ]

  const targets: Record<string, TargetConfiguration> = {
    // Combined check: lint + format in one command
    [checkTargetName]: {
      command: 'biome check {projectRoot}',
      cache: true,
      inputs: baseInputs,
      options: {
        cwd: '{workspaceRoot}'
      },
      metadata: {
        description: 'Run Biome linter and formatter checks (no fixes applied)',
        help: {
          command: `nx ${checkTargetName} <project>`,
          example: {
            options: {
              '--write': 'Apply safe fixes',
              '--unsafe': 'Apply safe + unsafe fixes'
            }
          }
        }
      }
    },

    // Lint only
    [lintTargetName]: {
      command: 'biome lint {projectRoot}',
      cache: true,
      inputs: baseInputs,
      options: {
        cwd: '{workspaceRoot}'
      },
      metadata: {
        description: 'Run Biome linter only',
        help: {
          command: `nx ${lintTargetName} <project>`,
          example: {
            options: {
              '--write': 'Apply safe fixes'
            }
          }
        }
      }
    },

    // Format with write
    [formatTargetName]: {
      command: 'biome format --write {projectRoot}',
      cache: true,
      inputs: baseInputs,
      options: {
        cwd: '{workspaceRoot}'
      },
      metadata: {
        description: 'Format code with Biome formatter',
        help: {
          command: `nx ${formatTargetName} <project>`,
          example: {}
        }
      }
    },

    // CI mode: check without writing, strict exit codes
    [ciTargetName]: {
      command: 'biome ci {projectRoot}',
      cache: true,
      inputs: baseInputs,
      options: {
        cwd: '{workspaceRoot}'
      },
      metadata: {
        description:
          'Run Biome checks in CI mode (no fixes, strict). Exits with error if any issues found.',
        help: {
          command: `nx ${ciTargetName} <project>`,
          example: {}
        }
      }
    }
  }

  return {
    projects: {
      [root]: {
        targets
      }
    }
  }
}
