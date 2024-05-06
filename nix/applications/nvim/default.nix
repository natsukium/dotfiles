{ pkgs, config, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
  buildInputs = with pkgs; [ nodejs ];
  lsp = with pkgs; [
    # astro
    nodePackages."@astrojs/language-server"
    # bash
    nodePackages.bash-language-server
    shellcheck
    shfmt
    # docker
    nodePackages.dockerfile-language-server-nodejs
    # hadolint
    docker-compose-language-service
    # javascript
    biome
    # lua
    lua-language-server
    stylua
    # nix
    nil
    nurpkgs.nixfmt
    # python
    nodePackages.pyright
    ruff
    # ruby
    solargraph
    rubocop
    # terraform
    terraform-ls
    # toml
    taplo
    # typescript
    nodePackages.typescript-language-server
    # typst
    typst-lsp
    typstfmt
    # yaml
    yaml-language-server
    # spell check
    typos-lsp
  ];
  parsers =
    p:
    with p; [
      astro
      bash
      c
      css
      dockerfile
      fish
      lua
      make
      markdown
      markdown_inline
      nix
      python
      query
      r
      ruby
      rust
      toml
      tsx
      typescript
      tree-sitter-typst
      vim
      vimdoc
      yaml
    ];
  plugins = import ./plugins.nix { inherit pkgs nurpkgs; };
  configFile = file: {
    "nvim/${file}".source = pkgs.substituteAll (
      {
        src = ./. + "/${file}";
        ts_parser_dirs = pkgs.lib.pipe (pkgs.vimPlugins.nvim-treesitter.withPlugins parsers).dependencies [
          (map toString)
          (builtins.concatStringsSep ",")
        ];
      }
      // plugins
    );
  };
  configFiles = files: builtins.foldl' (x: y: x // y) { } (map configFile files);
in
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped.override { treesitter-parsers = { }; };
    vimAlias = true;
    defaultEditor = true;
    extraPackages = buildInputs ++ lsp;
  };
  xdg.configFile =
    {
      "nvim/ftdetect".source = ./ftdetect;
    }
    // configFiles [
      "./init.lua"
      "./lua/misc.lua"
      "./lua/plugins/completion.lua"
      "./lua/plugins/dap.lua"
      "./lua/plugins/git.lua"
      "./lua/plugins/lsp.lua"
      "./lua/plugins/misc.lua"
      "./lua/plugins/test_runner.lua"
      "./lua/plugins/ui.lua"
    ];

  home.packages = [ pkgs.neovim-remote ];
}
