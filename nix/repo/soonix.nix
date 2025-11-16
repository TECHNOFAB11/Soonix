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
