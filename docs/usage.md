---
render_macros: false
---

# Usage Guide

This guide covers how to use Soonix to manage your project's configuration files, templates, and other assets.

## Installation

Add Soonix to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    soonix.url = "gitlab:TECHNOFAB/soonix?dir=lib";
  };
}
```

## Basic Usage

### 1. Simple Configuration File Generation

Generate a JSON configuration file from Nix data:

```nix
let
  shellHook = (soonix.lib { inherit pkgs; }).mkShellHook {
    hooks = {
      package-json = {
        output = "package.json";
        generator = "nix";
        data = {
          name = "my-project";
          version = "1.0.0";
          scripts = {
            dev = "vite dev";
            build = "vite build";
          };
          dependencies = {
            vite = "^4.0.0";
          };
        };
        opts = { format = "json"; };
      };
    };
  };
in
  pkgs.mkShell { inherit shellHook; }
```

### 2. Multiple Format Support

The `nix` generator supports various formats:

```nix
hooks = {
  # YAML configuration
  docker-compose = {
    output = "docker-compose.yml";
    generator = "nix";
    data = {
      version = "3.8";
      services = {
        web = {
          image = "nginx:alpine";
          ports = ["80:80"];
        };
      };
    };
    opts = { format = "yaml"; };
  };

  # TOML configuration  
  pyproject = {
    output = "pyproject.toml";
    generator = "nix";
    data = {
      build-system = {
        requires = ["hatchling"];
        build-backend = "hatchling.build";
      };
      project = {
        name = "my-python-project";
        version = "0.1.0";
      };
    };
    opts = { format = "toml"; };
  };
};
```

### 3. Template-Based Generation

Use Go templates for more complex file generation:

```nix
hooks = {
  dockerfile = {
    output = "Dockerfile";
    generator = "gomplate";
    data = {
      baseImage = "node:18-alpine";
      workdir = "/app";
      port = 3000;
      deps = ["curl" "git"];
    };
    opts.template = pkgs.writeText "dockerfile.tmpl" ''
      FROM {{ .baseImage }}
      
      WORKDIR {{ .workdir }}
      
      {{- if .deps }}
      RUN apk add --no-cache \
        {{- range $i, $dep := .deps }}
        {{- if $i }} \{{- end }}
        {{ $dep }}
        {{- end }}
      {{- end }}
      
      COPY package*.json ./
      RUN npm ci --only=production
      
      COPY . .
      
      EXPOSE {{ .port }}
      CMD ["npm", "start"]
    '';
  };
};
```

### 4. Jinja2 Templates

For Python-style templating:

```nix
hooks = {
  nginx-config = {
    output = "nginx.conf";
    generator = "jinja";
    data = {
      server_name = "example.com";
      port = 80;
      root = "/var/www/html";
      locations = [
        { path = "/api"; proxy_pass = "http://backend:8000"; }
        { path = "/static"; root = "/var/www/static"; }
      ];
    };
    opts.template = pkgs.writeText "nginx.conf.j2" ''
      server {
          listen {{ port }};
          server_name {{ server_name }};
          root {{ root }};
          
          {% for location in locations %}
          location {{ location.path }} {
              {% if location.proxy_pass %}
              proxy_pass {{ location.proxy_pass }};
              {% elif location.root %}
              root {{ location.root }};
              {% endif %}
          }
          {% endfor %}
      }
    '';
  };
};
```

### 5. Script Generation

Create executable scripts:

```nix
hooks = {
  dev-script = {
    output = "scripts/dev.sh";
    generator = "string";
    data = ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      echo "Starting development environment..."
      
      # Start database
      docker-compose up -d postgres
      
      # Run migrations
      npm run db:migrate
      
      # Start dev server
      npm run dev
    '';
    opts.executable = true;
  };
};
```

### 6. Using Existing Derivations

Include pre-built files or derivations:

```nix
hooks = {
  config-file = {
    output = ".myapprc";
    generator = "derivation";
    data = pkgs.writeText "myapprc" ''
      # Generated configuration
      api_url = "https://api.example.com"
      debug = true
    '';
  };
};
```

## Hook Configuration

### File Management Modes

Control how files are managed:

```nix
hooks = {
  # Symlink mode (default)
  dev-config = {
    output = "config.json";
    generator = "nix";
    data = { debug = true; };
    hook.mode = "link";  # Creates symlinks
  };

  # Copy mode - for tools that don't support symlinks or file is not gitignored and needs to be portable
  editable-config = {
    output = "editable.json";
    generator = "nix"; 
    data = { editable = true; };
    hook.mode = "copy";  # Copies files
  };
};
```

### GitIgnore Management

Control .gitignore entries:

```nix
hooks = {
  # Don't add to gitignore (you want to commit this file)
  committed-config = {
    output = "config.json";
    generator = "nix";
    data = { production = true; };
    hook.gitignore = false;
  };

  # Auto-add to gitignore (default behavior)
  generated-file = {
    output = "temp.json";
    generator = "nix";
    data = { temp = true; };
    hook.gitignore = true;  # Default
  };
};
```

### Post-Processing Commands

Run commands after file operations:

```nix
hooks = {
  formatted-json = {
    output = "package.json";
    generator = "nix";
    data = { /* ... */ };
    hook = {
      mode = "copy";
      extra = "npx prettier --write package.json";
    };
  };
  
  executable-script = {
    output = "build.sh";
    generator = "string";
    data = "#!/bin/bash\necho 'Building...'";
    hook.extra = "chmod +x build.sh";
  };
};
```

## Advanced Usage

### Environment-Specific Configurations

```nix
let
  mkConfig = env: {
    database_url = if env == "development" 
      then "sqlite:///dev.db"
      else "postgresql://prod-db:5432/app";
    debug = env == "development";
    log_level = if env == "development" then "debug" else "info";
  };
in {
  hooks = {
    dev-config = {
      output = "config.dev.json";
      generator = "nix";
      data = mkConfig "development";
      opts = { format = "json"; };
    };
    
    prod-config = {
      output = "config.prod.json";
      generator = "nix"; 
      data = mkConfig "production";
      opts = { format = "json"; };
    };
  };
}
```

### Complex Template Logic

```nix
hooks = {
  kubernetes-manifest = {
    output = "k8s/deployment.yaml";
    generator = "gomplate";
    data = {
      app = {
        name = "my-app";
        version = "1.2.3";
        replicas = 3;
        port = 8080;
      };
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "PORT"; value = "8080"; }
      ];
      secrets = [
        { name = "DB_PASSWORD"; secretName = "db-secret"; key = "password"; }
      ];
      resources = {
        requests = { memory = "128Mi"; cpu = "100m"; };
        limits = { memory = "512Mi"; cpu = "500m"; };
      };
    };
    opts.template = ./templates/deployment.yaml.tmpl;
  };
};
```

## Integration Patterns

### With Development Shells

Standard mkShell integration:

```nix
pkgs.mkShell {
  packages = with pkgs; [ nodejs python3 docker ];
  shellHook = soonix.mkShellHook { inherit hooks; };
}
```

### With Devshell

Using the devshell module:

```nix
{
  inputs = {
    devshell.url = "github:rensa-nix/devshell?dir=lib";
    soonix.url = "gitlab:TECHNOFAB/soonix?dir=lib";
  };
  
  outputs = { devshell, soonix, ... }: {
    # load pkgs etc...
    devShells.default = (devshell.lib { inherit pkgs; }).mkShell {
      imports = [ soonix.devshellModule ];

      packages = [ pkgs.hello ];

      soonix.hooks = {
        # Your hooks here
      };
    };
  };
}
```

## Troubleshooting

### Enable Logging

Set `SOONIX_LOG=true` to see detailed status messages:

```bash
SOONIX_LOG=true nix develop
```

### Manual Updates

Update the files without shellHook/devshells:

```bash
nix run .#soonix:update
```

### Check Generated Files

Inspect what Soonix would generate without writing files:

```bash
nix build .#soonixFiles
ls result/
```
