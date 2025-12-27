# Biome - Fast formatter and linter for JS/TS/JSON
# Generates ~/.config/biome/biome.json for consumer projects to extend
{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.biome;

  # Path to biome assets in dev-config repo
  biomeAssetsPath =
    if inputs ? dev-config
    then "${inputs.dev-config}/biome"
    else ../../../biome;

  # Path to root biome.json configuration
  biomeJsonPath =
    if inputs ? dev-config
    then "${inputs.dev-config}/biome.json"
    else ../../../biome.json;

  # Build the biome.json configuration from Nix options
  biomeConfig = {
    "$schema" = "https://biomejs.dev/schemas/2.3.8/schema.json";

    vcs = {
      enabled = cfg.vcs.enable;
      clientKind = cfg.vcs.clientKind;
      useIgnoreFile = cfg.vcs.useIgnoreFile;
      defaultBranch = cfg.vcs.defaultBranch;
    };

    files = {
      ignoreUnknown = cfg.files.ignoreUnknown;
    };

    formatter = {
      enabled = cfg.formatter.enable;
      indentStyle = cfg.formatter.indentStyle;
      indentWidth = cfg.formatter.indentWidth;
      lineWidth = cfg.formatter.lineWidth;
      lineEnding = cfg.formatter.lineEnding;
    };

    linter = {
      enabled = cfg.linter.enable;
      rules = cfg.linter.rules;
    };

    javascript = {
      formatter = {
        quoteStyle = cfg.javascript.formatter.quoteStyle;
        jsxQuoteStyle = cfg.javascript.formatter.jsxQuoteStyle;
        semicolons = cfg.javascript.formatter.semicolons;
        trailingCommas = cfg.javascript.formatter.trailingCommas;
        arrowParentheses = cfg.javascript.formatter.arrowParentheses;
        bracketSpacing = cfg.javascript.formatter.bracketSpacing;
      };
      parser = {
        unsafeParameterDecoratorsEnabled = cfg.javascript.parser.unsafeParameterDecoratorsEnabled;
      };
      globals = cfg.javascript.globals;
    };

    json = {
      parser = {
        allowComments = cfg.json.parser.allowComments;
        allowTrailingCommas = cfg.json.parser.allowTrailingCommas;
      };
      formatter = {
        trailingCommas = cfg.json.formatter.trailingCommas;
      };
    };

    overrides = cfg.overrides;
  };

  # Merge with extraConfig
  finalConfig = lib.recursiveUpdate biomeConfig cfg.extraConfig;

  # Generate JSON content
  biomeJsonContent = builtins.toJSON finalConfig;
in {
  options.dev-config.biome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Biome linter and formatter configuration";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.biome;
      description = "Biome package to use";
    };

    exportConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Export biome.json to ~/.config/biome/biome.json.
        Consumer projects can extend from this file using:
        "extends": ["~/.config/biome/biome.json"]
      '';
    };

    # VCS Integration
    vcs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable VCS integration (respects .gitignore)";
      };

      clientKind = lib.mkOption {
        type = lib.types.enum ["git"];
        default = "git";
        description = "VCS client type";
      };

      useIgnoreFile = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use .gitignore for file exclusion";
      };

      defaultBranch = lib.mkOption {
        type = lib.types.str;
        default = "main";
        description = "Default branch name for VCS operations";
      };
    };

    # Files configuration
    files = {
      ignoreUnknown = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Suppress diagnostics for unrecognized file types";
      };
    };

    # Formatter configuration
    formatter = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable formatter";
      };

      indentStyle = lib.mkOption {
        type = lib.types.enum ["tab" "space"];
        default = "space";
        description = "Indentation style";
      };

      indentWidth = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Number of spaces or tab width";
      };

      lineWidth = lib.mkOption {
        type = lib.types.int;
        default = 100;
        description = "Maximum line width before wrapping";
      };

      lineEnding = lib.mkOption {
        type = lib.types.enum ["lf" "crlf" "cr"];
        default = "lf";
        description = "Line ending style";
      };
    };

    # Linter configuration
    linter = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable linter";
      };

      rules = lib.mkOption {
        type = lib.types.attrs;
        default = {
          recommended = true;
          # Correctness - auto-fixable
          # NOTE: useImportExtensions removed - not needed for TypeScript-only projects
          correctness = {
            noUnusedImports = "error";
            noUnusedVariables = "error";
            noUnusedPrivateClassMembers = "error";
          };
          # Style - ESM enforcement + auto-fixable (Direct Equality Philosophy)
          style = {
            # Backstop rules (ban wrong patterns)
            noCommonJs = "error";
            noDefaultExport = "warn";
            noNamespace = "error";
            noNonNullAssertion = "error";
            noProcessEnv = "warn";
            # Direct equality rules (enforce correct patterns)
            useImportType = "error";
            useExportType = "error";
            useNodejsImportProtocol = "error";
            useConst = "error";
            useTemplate = "error";
            useSingleVarDeclarator = "error";
            useConsistentArrayType = {
              level = "error";
              options = {syntax = "shorthand";};
            };
            useShorthandAssign = "error";
            useExponentiationOperator = "error";
            useAsConstAssertion = "error";
            useEnumInitializers = "error";
          };
          # Suspicious - strict type safety
          # NOTE: noImplicitAnyLet removed - does NOT exist in Biome (expert validation)
          suspicious = {
            noExplicitAny = "error";
            noConsole = "warn";
            noDoubleEquals = "error";
            noArrayIndexKey = "warn";
            noAssignInExpressions = "error";
            noAsyncPromiseExecutor = "error";
            noConfusingVoidType = "error";
            noConstEnum = "error";
            noDebugger = "error";
            noDuplicateObjectKeys = "error";
            noEmptyBlockStatements = "warn";
            noExportsInTest = "error";
            noExtraNonNullAssertion = "error";
            noFallthroughSwitchClause = "error";
            noGlobalIsFinite = "error";
            noGlobalIsNan = "error";
            noMisleadingCharacterClass = "error";
            noMisleadingInstantiator = "error";
            noPrototypeBuiltins = "error";
            noRedeclare = "error";
            noSelfCompare = "error";
            noShadowRestrictedNames = "error";
            noUnsafeDeclarationMerging = "error";
            noUnsafeNegation = "error";
            # Direct equality rules
            useAwait = "error";
            useDefaultSwitchClauseLast = "error";
            useGetterReturn = "error";
            useIsArray = "error";
            useNamespaceKeyword = "error";
          };
          # Complexity - clean code
          complexity = {
            noBannedTypes = "error";
            noExcessiveCognitiveComplexity = {
              level = "error"; # Changed from warn to error per user decision
              options = {
                maxAllowedComplexity = 15;
              };
            };
            noForEach = "warn";
            noStaticOnlyClass = "error";
            noUselessCatch = "error";
            noUselessConstructor = "error";
            noUselessEmptyExport = "error";
            noUselessFragments = "error";
            noUselessLabel = "error";
            noUselessLoneBlockStatements = "error";
            noUselessRename = "error";
            noUselessSwitchCase = "error";
            noUselessTernary = "error";
            noUselessThisAlias = "error";
            noUselessTypeConstraint = "error";
            noVoid = "error";
            # Direct equality rules
            useFlatMap = "error";
            useLiteralKeys = "error";
            useOptionalChain = "error";
            useSimplifiedLogicExpression = "error";
          };
          # Performance - strict enforcement (75% build improvement from barrel file ban)
          performance = {
            noAccumulatingSpread = "error";
            noBarrelFile = "error"; # Changed from warn to error per user decision
            noDelete = "warn";
            noReExportAll = "error"; # Changed from warn to error per user decision
          };
          # Security
          security = {
            noDangerouslySetInnerHtml = "error";
            noGlobalEval = "error";
          };
        };
        description = "Linter rules with strict ESM enforcement and Direct Equality Philosophy";
        example = lib.literalExpression ''
          {
            recommended = true;
            correctness.noUnusedImports = "error";
            style.noCommonJs = "error";
            suspicious.noExplicitAny = "error";
          }
        '';
      };
    };

    # JavaScript/TypeScript configuration
    javascript = {
      formatter = {
        quoteStyle = lib.mkOption {
          type = lib.types.enum ["single" "double"];
          default = "single";
          description = "Quote style for strings";
        };

        jsxQuoteStyle = lib.mkOption {
          type = lib.types.enum ["single" "double"];
          default = "double";
          description = "Quote style for JSX attributes";
        };

        semicolons = lib.mkOption {
          type = lib.types.enum ["always" "asNeeded"];
          default = "asNeeded";
          description = "Semicolon insertion style";
        };

        trailingCommas = lib.mkOption {
          type = lib.types.enum ["all" "es5" "none"];
          default = "none";
          description = "Trailing comma style";
        };

        arrowParentheses = lib.mkOption {
          type = lib.types.enum ["always" "asNeeded"];
          default = "always";
          description = "Arrow function parentheses style";
        };

        bracketSpacing = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Add spaces inside object braces";
        };
      };

      parser = {
        unsafeParameterDecoratorsEnabled = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable experimental parameter decorators";
        };
      };

      globals = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Global variables to allow (e.g., Effect, NodeJS)";
        example = ["Effect" "NodeJS" "process"];
      };
    };

    # JSON configuration
    json = {
      parser = {
        allowComments = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Allow comments in JSON files (JSONC support)";
        };

        allowTrailingCommas = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Allow trailing commas in JSON files";
        };
      };

      formatter = {
        trailingCommas = lib.mkOption {
          type = lib.types.enum ["all" "none"];
          default = "none";
          description = "Trailing comma style for JSON output";
        };
      };
    };

    # Overrides for specific file patterns
    overrides = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          includes = ["**/*.test.ts" "**/*.spec.ts" "**/*.test.tsx" "**/*.spec.tsx"];
          linter.rules.suspicious.noExplicitAny = "off";
        }
        {
          includes = ["**/index.ts" "**/index.tsx"];
          linter.rules.style.noDefaultExport = "off";
          linter.rules.performance.noBarrelFile = "off";
        }
        {
          includes = ["**/*.config.ts" "**/*.config.js" "**/*.config.mjs"];
          linter.rules.style.noDefaultExport = "off";
        }
        {
          includes = ["**/nx.json" "**/project.json" "**/package.json"];
          json.parser.allowComments = true;
          json.parser.allowTrailingCommas = false;
        }
      ];
      description = "Override rules for specific file patterns";
      example = lib.literalExpression ''
        [
          {
            includes = ["**/*.test.ts"];
            linter.rules.suspicious.noExplicitAny = "off";
          }
        ]
      '';
    };

    # GritQL custom patterns
    gritql = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GritQL custom lint patterns";
      };

      patternsSource = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default =
          if builtins.pathExists biomeAssetsPath
          then "${biomeAssetsPath}/gritql-patterns"
          else null;
        description = "Path to GritQL patterns directory";
      };
    };

    # Extra configuration (merged at top level)
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional Biome configuration to merge";
      example = lib.literalExpression ''
        {
          overrides = [
            {
              includes = ["**/*.test.ts"];
              linter.rules.suspicious.noExplicitAny = "off";
            }
          ];
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Biome package
    home.packages = [cfg.package];

    # Export biome.json to ~/.config/biome/
    xdg.configFile = lib.mkIf cfg.exportConfig {
      "biome/biome.json" = lib.mkIf (biomeJsonPath != null) {
        source = biomeJsonPath;
      };

      # Symlink .biomeignore file
      "biome/.biomeignore" = lib.mkIf (biomeAssetsPath != null) {
        source = "${biomeAssetsPath}/.biomeignore";
      };

      # Symlink GritQL patterns if enabled and available
      "biome/gritql-patterns" = lib.mkIf (cfg.gritql.enable && cfg.gritql.patternsSource != null) {
        source = cfg.gritql.patternsSource;
      };
    };
  };
}
