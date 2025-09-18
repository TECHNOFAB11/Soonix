{inputs, ...}: let
  inherit (inputs) pkgs soonix doclib;

  optionsDoc = doclib.mkOptionDocs {
    module = soonix.module;
    roots = [
      {
        url = "https://gitlab.com/TECHNOFAB/soonix/-/blob/main/lib";
        path = "${inputs.self}/lib";
      }
    ];
  };
  optionsDocs = pkgs.runCommand "options-docs" {} ''
    mkdir -p $out
    ln -s ${optionsDoc} $out/options.md
  '';
in
  (doclib.mkDocs {
    docs."default" = {
      base = "${inputs.self}";
      path = "${inputs.self}/docs";
      material = {
        enable = true;
        umami = {
          enable = true;
          src = "https://analytics.tf/umami";
          siteId = "e8b0ca9c-c540-41b0-8eb8-1b2fcc5e57f7";
          domains = ["soonix.projects.tf"];
        };
      };
      macros = {
        enable = true;
        includeDir = toString optionsDocs;
      };
      config = {
        site_name = "Soonix";
        site_url = "https://soonix.projects.tf";
        repo_name = "TECHNOFAB/soonix";
        repo_url = "https://gitlab.com/TECHNOFAB/soonix";
        theme = {
          logo = "images/logo.svg";
          icon.repo = "simple/gitlab";
          favicon = "images/logo.svg";
        };
        nav = [
          {"Introduction" = "index.md";}
          {"Usage" = "usage.md";}
          {"Integrations" = "integrations.md";}
          {"Options" = "options.md";}
        ];
        markdown_extensions = [
          {
            "pymdownx.highlight".pygments_lang_class = true;
          }
          "pymdownx.inlinehilite"
          "pymdownx.snippets"
          "pymdownx.superfences"
          "pymdownx.escapeall"
          "fenced_code"
        ];
      };
    };
  }).packages
  // {
    inherit optionsDocs;
  }
