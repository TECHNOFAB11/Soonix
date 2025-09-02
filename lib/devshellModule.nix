{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  soonixModule = ./module.nix;
in {
  options = {
    soonix = mkOption {
      type = types.submodule {
        # propagate pkgs to the soonix module
        _module.args.pkgs = pkgs;
        imports = [soonixModule];
      };
      default = {};
    };
    soonixShellHook = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Set the shell hook manually, useful if you already use `soonix.make` and
        want to add the devshell integration.
      '';
    };
  };

  config.enterShellCommands.soonix = {
    text =
      if config.soonixShellHook != null
      then config.soonixShellHook
      else config.soonix.shellHook;
    deps = ["env"];
  };
}
