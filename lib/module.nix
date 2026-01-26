{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) types mkOption concatMapStringsSep;
  soonix_lib = import ./. {inherit pkgs;};
  inherit (soonix_lib) engines buildAllFiles;
in {
  options = {
    hooks = mkOption {
      type = types.attrsOf (types.submodule ({
        name,
        config,
        ...
      }: {
        options = {
          name = mkOption {
            type = types.str;
            internal = true;
            default = name;
          };

          output = mkOption {
            type = types.str;
            description = ''
              The relative path where the generated file should be placed.
            '';
          };

          generator = mkOption {
            type = types.enum ["nix" "string" "derivation" "gomplate" "jinja" "template"];
            description = ''
              Which engine to use for content generation.
            '';
            default = "nix";
          };

          data = mkOption {
            type = types.anything;
            description = ''
              The input data for the chosen generator.
            '';
          };

          opts = mkOption {
            type = types.attrs;
            default = {};
            description = ''
              Generator-specific options.
            '';
          };

          hook = mkOption {
            type = types.submodule {
              options = {
                mode = mkOption {
                  type = types.enum ["link" "copy"];
                  default = "link";
                  description = ''
                    How the file should be managed (link or copy).
                  '';
                };

                gitignore = mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    Whether to add the output path to .gitignore.
                  '';
                };

                extra = mkOption {
                  type = types.str;
                  default = "";
                  description = ''
                    Additional bash commands to execute after file operation.
                  '';
                };
              };
            };
            default = {};
            description = ''
              Hook-specific options.
            '';
          };

          generatedDerivation = mkOption {
            type = types.package;
            internal = true;
            readOnly = true;
            description = ''
              The generated derivation for this file.
            '';
          };
        };

        config = {
          generatedDerivation =
            (engines.${config.generator} or (throw "Generator ${config.generator} not found"))
            {
              inherit (config) opts data name;
            };
        };
      }));
      default = {};
      description = ''
        Configuration of the hooks.
      '';
    };

    shellHook = mkOption {
      type = types.str;
      readOnly = true;
      description = ''
        Generated shell hook script (as a string) for managing all files. (readonly)
      '';
    };
    shellHookFile = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        Generated shell hook script for managing all files. (readonly)
      '';
    };
    devshellModule = mkOption {
      type = types.attrs;
      readOnly = true;
      description = ''
        Devshell module with automatically configured hooks, just import and you're good to go. (readonly)
      '';
    };

    finalFiles = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        Aggregated derivation containing all managed files. (readonly)
      '';
    };
    packages = mkOption {
      type = types.attrsOf types.package;
      readOnly = true;
      description = ''
        Packages for updating the hooks without a devshell. (readonly)
      '';
      example = {
        "soonix:update" = "<derivation>";
      };
    };
  };

  config = let
    hooks = config.hooks;
    hookNames = builtins.attrNames hooks;

    runHooks = concatMapStringsSep "\n" (hookName: let
      hook = hooks.${hookName};
      modes = {
        link =
          # sh
          ''
            if [[ ! -L "${hook.output}" ]] || [[ "$(readlink "${hook.output}")" != "${hook.generatedDerivation}" ]]; then
              _soonix_log "info" "${hookName}" "Creating symlink: ${hook.output} -> ${hook.generatedDerivation}"
              mkdir -p "$(dirname "${hook.output}")"
              ln -sf "${hook.generatedDerivation}" "${hook.output}"
              _changed=true
            else
              _soonix_log "info" "${hookName}" "Symlink up to date: ${hook.output}"
            fi
          '';
        copy =
          # sh
          ''
            if [[ ! -f "${hook.output}" ]] || ! cmp -s "${hook.generatedDerivation}" "${hook.output}"; then
              _soonix_log "info" "${hookName}" "Copying file: ${hook.generatedDerivation} -> ${hook.output}"
              mkdir -p "$(dirname "${hook.output}")"
              # required since they're read only
              rm -f "${hook.output}"
              cp "${hook.generatedDerivation}" "${hook.output}"
              _changed=true
            else
              _soonix_log "info" "${hookName}" "File up to date: ${hook.output}"
            fi
          '';
      };

      optionalGitignore =
        if hook.hook.gitignore
        then ''
          _soonix_add_to_gitignore "${hook.output}"
        ''
        else "";
    in
      # sh
      ''
        # Process hook: ${hookName}
        while IFS= read -r line; do
          case "$line" in
            UPDATED) _soonix_updated+=("${hookName}") ;;
            UPTODATE) _soonix_uptodate+=("${hookName}") ;;
            *) echo "$line" ;;
          esac
        done < <(
          set -euo pipefail
          _changed=false

          ${modes.${hook.hook.mode} or (throw "Mode ${hook.hook.mode} doesnt exist")}

          # Add to gitignore if requested
          ${optionalGitignore}

          # Run extra commands if file changed
          if [[ "$_changed" == "true" && -n "${hook.hook.extra}" ]]; then
            _soonix_log "info" "${hookName}" "Running extra command: ${hook.hook.extra}"
            eval "${hook.hook.extra}"
          fi

          if [[ "$_changed" == "true" ]]; then
            echo "UPDATED"
          else
            echo "UPTODATE"
          fi
        ) || {
          _soonix_log "error" "${hookName}" "Failed to process hook"
          _soonix_failed+=("${hookName}")
        }
      '')
    hookNames;

    generatedShellHook =
      # sh
      ''
        _soonix_log() {
          local level="$1"
          local hook="$2"
          local message="$3"
          [[ "''${SOONIX_LOG-}" == "true" ]] && echo "$level [$hook]: $message" || true
        }

        _soonix_add_to_gitignore() {
          local file="$1"
          local gitignore=".gitignore"

          if [[ ! -f "$gitignore" ]]; then
            touch "$gitignore"
          fi

          # Check if file is already in gitignore
          if ! grep -Fxq "/$file" "$gitignore"; then
            # Add sentinel comments if not present
            if ! grep -q "# soonix" "$gitignore"; then
              echo "" >> "$gitignore"
              echo "# soonix" >> "$gitignore"
              echo "# end soonix" >> "$gitignore"
            fi

            # Insert the file path before the end comment
            ${pkgs.gnused}/bin/sed -i "/# end soonix/i /$file" "$gitignore"
          fi
        }

        _soonix_updated=()
        _soonix_failed=()
        _soonix_uptodate=()

        ${runHooks}

        local output=$'\E[msoonix:\E[38;5;8m'
        local status=0

        if [[ ''${#_soonix_updated[@]} -gt 0 ]]; then
          output="$output [updated: ''${_soonix_updated[*]}]" >&2
        fi
        if [[ ''${#_soonix_uptodate[@]} -gt 0 ]]; then
          output="$output [unchanged: ''${_soonix_uptodate[*]}]" >&2
        fi
        if [[ ''${#_soonix_failed[@]} -gt 0 ]]; then
          output="$output [failed: ''${_soonix_failed[*]}]" >&2
          status=1
        fi

        printf "%s\E[m\n" "$output" >&2

        if [[ $status -eq 1 ]]; then
          exit 1
        fi
      '';

    allFiles =
      lib.mapAttrsToList (name: hook: {
        src = hook.generatedDerivation;
        path = hook.output;
      })
      hooks;
  in rec {
    # nothing to do if no hooks exist
    shellHook =
      if (builtins.length hookNames > 0)
      then generatedShellHook
      else "";
    shellHookFile = pkgs.writeShellScript "shellHook" shellHook;
    devshellModule = {
      imports = [./devshellModule.nix];
      config.soonixShellHook = shellHook;
    };
    finalFiles = buildAllFiles allFiles;
    # make it simpler to update the hooks without any devshell
    packages."soonix:update" = pkgs.writeShellScriptBin "soonix:update" ''
      function _soonix() {
        ${shellHook}
      }
      _soonix
    '';
  };
}
