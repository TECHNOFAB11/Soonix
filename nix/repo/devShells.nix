{
  cell,
  inputs,
  ...
}: let
  inherit (inputs) pkgs devshell soonix treefmt;
in {
  default = devshell.mkShell {
    imports = [soonix.devshellModule];
    packages = [
      pkgs.alejandra
      pkgs.nil
      (treefmt.mkWrapper pkgs {
        programs = {
          alejandra.enable = true;
          mdformat.enable = true;
        };
      })
    ];

    soonix.hooks.test = {
      output = "test.yaml";
      generator = "nix";
      data = {
        name = "soonix-test";
        version = "1.0.0";
      };
      opts.format = "yaml";
      hook = {
        mode = "copy";
        gitignore = true;
      };
    };
  };
}
