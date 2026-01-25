# Soonix

Soonix is a lightweight, declarative tool for managing configuration files, build scripts, and other project assets using the Nix module system. It provides a clean alternative to Nixago with reduced complexity and removed legacy code.

## What is Soonix?

Soonix helps you:

- **Generate configuration files** from Nix data structures
- **Template complex configurations** using Go templates or Jinja2
- **Manage file lifecycles** automatically with shell hooks
- **Keep generated files in sync** with your Nix configuration
- **Integrate seamlessly** with development environments

## Key Features

### Multiple Generation Engines

- **nix**: Convert Nix data to JSON, YAML, TOML, INI, XML formats
- **string**: Output raw string content with optional executable permissions
- **derivation**: Use existing Nix derivations as file content
- **gomplate**: Advanced Go template rendering via gomplate
- **jinja**: Python Jinja2 template rendering
- **mustache**: Mustache template rendering

### Automatic File Management

Shell hooks automatically update files when entering your development environment, with intelligent change detection and status reporting.

### Flexible File Handling

Choose between symlinks or file copies on a per-file basis.

### GitIgnore Integration

Automatically manage .gitignore entries for generated files to keep your repository clean.

## Quick Example

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
          data = { 
            extends = ["eslint:recommended"];
            rules = {
              "no-unused-vars" = "error";
            };
          };
          opts = { format = "json"; };
        };

        dockerfile = {
          output = "Dockerfile";
          generator = "gomplate";
          data = {
            baseImage = "node:18-alpine";
            port = 3000;
          };
          opts.template = ./templates/dockerfile.tmpl;
        };
      };
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [ pkgs.nodejs pkgs.docker ];
      inherit shellHook;
    };
  };
}
```

When you enter this development environment, Soonix will:

1. Generate `.eslintrc.json` with your ESLint configuration
1. Render `Dockerfile` from your template with the provided data
1. Add both files to `.gitignore` automatically
1. Report status of file updates

## Why Soonix over Nixago?

Soonix is designed as a cleaner, more maintainable alternative to Nixago:

- **Reduced complexity**: Streamlined codebase without legacy features
- **Better error handling**: Clear error messages and status reporting
- **Modern architecture**: Built with current Nix best practices
- **Focused scope**: Does one thing well rather than trying to be everything

## Getting Started

Ready to start using Soonix? Check out the [Usage Guide](./usage.md) for detailed
setup instructions and examples, or browse the [Integration Guide](./integrations.md)
to see how to use Soonix with different development tools and frameworks.
