{
  inputs = {
    devshell-lib.url = "gitlab:rensa-nix/devshell?dir=lib";
    nixtest-lib.url = "gitlab:TECHNOFAB/nixtest?dir=lib";
    nixmkdocs-lib.url = "gitlab:TECHNOFAB/nixmkdocs?dir=lib";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      flake = false;
    };
  };
  outputs = i:
    i
    // {
      ntlib = i.nixtest-lib.lib {inherit (i.parent) pkgs;};
      devshell = i.devshell-lib.lib {inherit (i.parent) pkgs;};
      doclib = i.nixmkdocs-lib.lib {inherit (i.parent) pkgs;};
      soonix = import "${i.parent.self}/lib" {inherit (i.parent) pkgs;};
      treefmt = import i.treefmt-nix;
    };
}
