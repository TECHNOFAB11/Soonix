{
  inputs,
  ...
}: let
  inherit (inputs) soonix;
in
  (soonix.make {
    hooks = {
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
    };
  }).config
