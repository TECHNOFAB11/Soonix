{
  cell,
  inputs,
  ...
}: let
  inherit (inputs) pkgs devshell soonix treefmt;
  soonixShellHook = cell.soonix.shellHook;
in {
  default = devshell.mkShell {
    imports = [soonix.devshellModule];
    packages = [
      pkgs.nil
      (treefmt.mkWrapper pkgs {
        programs = {
          alejandra.enable = true;
          mdformat.enable = true;
        };
      })
    ];
    inherit soonixShellHook;
  };
}
