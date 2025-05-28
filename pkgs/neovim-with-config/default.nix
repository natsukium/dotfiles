{
  lib,
  neovim-unwrapped,
  neovimUtils,
  vimPlugins,
  wrapNeovimUnstable,
  replaceVars,

  # runtime dependencies
  astro-language-server,
  basedpyright,
  bash-language-server,
  biome,
  docker-compose-language-service,
  dockerfile-language-server-nodejs,
  hadolint,
  lua-language-server,
  nixd,
  nixfmt-rfc-style,
  nurl,
  rubocop,
  ruff,
  shellcheck,
  shfmt,
  solargraph,
  stylua,
  taplo,
  terraform-ls,
  tinymist,
  typescript-language-server,
  typos-lsp,
  typstyle,
  vscode-langservers-extracted,
  wakatime-cli,
  yaml-language-server,
}:
let
  mapBuiltinPluginToPath = map (p: "$out/share/nvim/runtime/plugin/${p}");
  disabledBuiltinPluginPaths = mapBuiltinPluginToPath [
    "gzip.vim"
    "matchit.vim"
    "matchparen.vim"
    "netrwPlugin.vim"
    "tarPlugin.vim"
    "tohtml.lua"
    "tutor.vim"
    "zipPlugin.vim"
  ];

  neovim-unwrapped' = neovim-unwrapped.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        rm ${lib.concatStringsSep " " disabledBuiltinPluginPaths}
      '';
  });

  language-servers = [
    # astro
    astro-language-server
    # bash
    bash-language-server
    shellcheck
    shfmt
    # docker
    dockerfile-language-server-nodejs
    hadolint
    docker-compose-language-service
    # javascript
    biome
    # json
    vscode-langservers-extracted
    # lua
    lua-language-server
    stylua
    # nix
    nixd
    nixfmt-rfc-style
    # python
    basedpyright
    ruff
    # ruby
    solargraph
    rubocop
    # terraform
    terraform-ls
    # toml
    taplo
    # typescript
    typescript-language-server
    # typst
    tinymist
    typstyle
    # yaml
    yaml-language-server
    # spell check
    typos-lsp
  ];

  tools = [
    nurl
    (wakatime-cli.overrideAttrs { __darwinAllowLocalNetworking = true; })
  ];

  extraWrapperArgs = [
    "--suffix"
    "PATH"
    ":"
    (lib.makeBinPath (language-servers ++ tools))
  ];

  config = neovimUtils.makeNeovimConfig {
    withNodeJs = true; # for copilot
    withRuby = false;
    withPython3 = false;
    vimAlias = true;
    luaRcContent = builtins.readFile (
      replaceVars ./init.lua {
        myconfig = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.difference ./. (
            lib.fileset.unions [
              ./init.lua
              ./plugins.nix
              ./default.nix
            ]
          );
        };
      }
    );

    plugins = import ./plugins.nix { inherit vimPlugins; };

  };
in
(wrapNeovimUnstable neovim-unwrapped' (
  # if wrapperArgs is defined directly in config, it will somehow be overwritten
  config // { wrapperArgs = config.wrapperArgs ++ extraWrapperArgs; }
))
