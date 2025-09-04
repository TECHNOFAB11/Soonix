{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ren.url = "gitlab:rensa-nix/core?dir=lib";
  };

  outputs = {
    self,
    ren,
    ...
  } @ inputs:
    ren.buildWith
    {
      inherit inputs;
      cellsFrom = ./nix;
      transformInputs = system: i:
        i
        // {
          pkgs = import i.nixpkgs {inherit system;};
        };
      cellBlocks = with ren.blocks; [
        (simple "devShells")
        (simple "tests")
        (simple "docs")
        (simple "soonix")
        (simple "ci")
      ];
    }
    {
      packages = ren.select self [
        ["repo" "tests"]
        ["repo" "docs"]
        ["repo" "ci" "packages"]
        ["repo" "soonix" "packages"]
      ];
    };
}
