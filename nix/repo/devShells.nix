{inputs, ...}: let
  inherit (inputs) pkgs devshell soonix;
in {
  default = devshell.mkShell {
    imports = [soonix.devshellModule];
    packages = [
      pkgs.alejandra
      pkgs.nil
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
