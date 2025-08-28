# Soonix

Soonix helps you declaratively manage configuration files, build scripts, etc. using the Nix module system.
It minimizes configuration clutter and provides shell hooks for automatic file management.

Heavily based on and inspired by [Nixago](https://github.com/nix-community/nixago), thus the name (ago \<-> soon, if that wasn't obvious).

## Features

- **Declarative Configuration**: Uses Nix modules for type-safe, declarative file management
- **Multiple Engines**: Support for JSON/YAML/TOML, templates, scripts, and more
- **Shell Hooks**: Automatic file management with status tracking
- **Flexible File Handling**: Choose between symlinks and copies based on your needs
- **GitIgnore Integration**: Automatic management of .gitignore entries

## Quick Start

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    soonix.url = "gitlab:TECHNOFAB/soonix?dir=lib";
  };

  outputs = { nixpkgs, soonix, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    shellHook = (soonix.lib { inherit pkgs; }).mkShellHook {
      hooks = {
        eslintrc = {
          output = ".eslintrc.json";
          generator = "nix";
          data = { extends = ["eslint:recommended"]; };
          opts = { format = "json"; };
        };
      };
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [ pkgs.jq ];
      inherit shellHook;
    };
  };
}
```

If you use [rensa-nix/devshell](https://devshell.rensa.projects.tf), you can also
use the `devshellModule` for easy integration, see the docs for more.

## Available Engines

- **`nix`**: Convert Nix data to JSON, YAML, TOML, INI, XML formats
- **`string`**: Output raw string content with optional executable permissions
- **`derivation`**: Use existing Nix derivations as file content
- **`gotmpl`**: Advanced Go template rendering via gomplate
- **`jinja`**: Python Jinja2 template rendering

## Docs

[Docs](https://soonix.projects.tf)
