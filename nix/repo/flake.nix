{
  inputs = {
    devshell-lib.url = "gitlab:rensa-nix/devshell?dir=lib";
    nixtest-lib.url = "gitlab:TECHNOFAB/nixtest?dir=lib";
  };
  outputs = i:
    i
    // {
      ntlib = i.nixtest-lib.lib {inherit (i.parent) pkgs;};
      devshell = i.devshell-lib.lib {inherit (i.parent) pkgs;};
      soonix = import "${i.parent.self}/lib" {inherit (i.parent) pkgs;};
    };
}
