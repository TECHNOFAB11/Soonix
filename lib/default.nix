{
  pkgs,
  lib ? pkgs.lib,
  ...
}: let
  inherit (lib) evalModules;

  soonix_lib = import ./lib.nix {inherit pkgs lib;};
in rec {
  inherit (soonix_lib) engines buildAllFiles;

  module = ./module.nix;
  devshellModule = ./devshellModule.nix;

  make = userConfig:
    evalModules {
      specialArgs = {inherit pkgs;};
      modules = [
        module
        userConfig
      ];
    };

  mkShellHook = userConfig: (make userConfig).config.shellHook;
}
