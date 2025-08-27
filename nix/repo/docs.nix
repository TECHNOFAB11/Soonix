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
        repo_name = "TECHNOFAB/soonix";
        repo_url = "https://gitlab.com/TECHNOFAB/soonix";
        theme = {
          logo = "images/logo.png";
          icon.repo = "simple/gitlab";
          favicon = "images/favicon.png";
        };
        nav = [
          {"Introduction" = "index.md";}
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
