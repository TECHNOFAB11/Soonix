{
  inputs = {
    devshell-lib.url = "gitlab:rensa-nix/devshell/v0.1.0?dir=lib";
    devtools-lib.url = "gitlab:rensa-nix/devtools/v0.1.0?dir=lib";
    nixtest-lib.url = "gitlab:TECHNOFAB/nixtest/v1.2.1?dir=lib";
    nixmkdocs-lib.url = "gitlab:TECHNOFAB/nixmkdocs?dir=lib";
    nix-gitlab-ci-lib.url = "gitlab:TECHNOFAB/nix-gitlab-ci/3.1.2?dir=lib";
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
      cilib = i.nix-gitlab-ci-lib.lib {inherit (i.parent) pkgs;};
      soonix = import "${i.parent.self}/lib" {inherit (i.parent) pkgs;};
      treefmt = import i.treefmt-nix;
    };
}
