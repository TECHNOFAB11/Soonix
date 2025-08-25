{
  ntlib,
  soonix,
  ...
}: let
  hooks = {
    test = {
      output = "out/test.json";
      generator = "nix";
      data = {
        name = "soonix-test";
        version = "1.0.0";
      };
      opts.format = "json";
      hook = {
        mode = "copy";
        gitignore = false;
      };
    };
    gomplate = {
      output = "gotmpl";
      generator = "gotmpl";
      data.hello = "world";
      opts.template = ./fixtures/gotmpl_template;
    };
    jinja = {
      output = "jinja";
      generator = "jinja";
      data.hello = "world";
      opts.template = ./fixtures/jinja_template;
    };
  };
in {
  suites."Soonix Tests" = {
    pos = __curPos;
    tests = [
      {
        name = "files get generated correctly";
        type = "script";
        script = let
          finalFiles = (soonix.make {inherit hooks;}).config.finalFiles;
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${finalFiles}/out/test.json" "should exist"
            assert_file_contains ${finalFiles}/out/test.json "soonix-test"

            assert "-f ${finalFiles}/gotmpl" "should exist"
            assert_file_contains ${finalFiles}/gotmpl "Hello world"

            assert "-f ${finalFiles}/jinja" "should exist"
            assert_file_contains ${finalFiles}/jinja "Hello world"
          '';
      }
      {
        name = "shell hook";
        type = "script";
        script = let
          shellHook = ntlib.helpers.toPrettyFile (soonix.mkShellHook {inherit hooks;});
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}
            assert "-f ${shellHook}" "should exist"
            assert_file_contains ${shellHook} "gomplate"
          '';
      }
    ];
  };
}
