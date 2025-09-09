{
  cell,
  inputs,
  ...
}: let
  inherit (inputs) pkgs devshell treefmt;
in {
  default = devshell.mkShell {
    imports = [cell.soonix.devshellModule];
    packages = [
      pkgs.nil
      (treefmt.mkWrapper pkgs {
        programs = {
          alejandra.enable = true;
          mdformat.enable = true;
        };
      })
    ];
  };
}
