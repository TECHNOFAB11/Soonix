{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  soonixModule = ./module.nix;
in {
  options.soonix = mkOption {
    type = types.submodule {
      # propagate pkgs to the soonix module
      _module.args.pkgs = pkgs;
      imports = [soonixModule];
    };
    default = {};
  };

  config.enterShellCommands.soonix = {
    text = config.soonix.shellHook;
    deps = ["env"];
  };
}
