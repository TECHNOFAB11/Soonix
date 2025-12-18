{
  inputs,
  cell,
  ...
}: let
  inherit (inputs) soonix;
  inherit (cell) ci;
in
  (soonix.make {
    hooks = {
      ci = ci.soonix;
      renovate = {
        output = ".gitlab/renovate.json5";
        data = {
          extends = ["config:recommended"];
          postUpgradeTasks.commands = [
            "nix-portable nix run .#soonix:update"
          ];
          lockFileMaintenance = {
            enabled = true;
            extends = ["schedule:monthly"];
          };
          nix.enabled = true;
          gitlabci.enabled = false;
        };
        hook = {
          mode = "copy";
          gitignore = false;
        };
        opts.format = "json";
      };
      test = {
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
      testJson = {
        output = "test.json";
        data.hello = "world";
        opts.format = "json";
        hook = {
          mode = "copy";
          gitignore = true;
        };
      };
    };
  }).config
