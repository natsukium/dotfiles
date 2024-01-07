{
  pkgs,
  config,
  ...
}: let
  nurpkgs = config.nur.repos.natsukium;
  buildInputs = with pkgs; [
    nodejs_18
  ];
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
    black
    nodePackages.pyright
    ruff
    # terraform
    terraform-ls
    # typescript
    nodePackages.typescript-language-server
  ];
  parsers = p:
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
      rust
      toml
      tsx
      typescript
      vim
      vimdoc
      yaml
    ];
  plugins = import ./plugins.nix {inherit pkgs nurpkgs;};
  ftdetectAstro = ''
    vim.filetype.add({
      extension = {
        astro = "astro"
      }
    })
  '';
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
  configFiles = files: builtins.foldl' (x: y: x // y) {} (map configFile files);
in {
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped.override {
      treesitter-parsers = {};
    };
    vimAlias = true;
    defaultEditor = true;
    extraPackages = buildInputs ++ lsp;
  };
  xdg.configFile =
    {
      "nvim/ftdetect/astro.lua".text = ftdetectAstro;
    }
    // configFiles [
      "./init.lua"
      "./lua/plugins/completion.lua"
      "./lua/plugins/dap.lua"
      "./lua/plugins/lsp.lua"
      "./lua/plugins/misc.lua"
      "./lua/plugins/test_runner.lua"
      "./lua/plugins/ui.lua"
    ];

  home.packages = [
    pkgs.neovim-remote
  ];
}
