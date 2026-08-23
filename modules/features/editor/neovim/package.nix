{
  lib,
  neovim-unwrapped,
  vimPlugins,
  wrapNeovimUnstable,

  # runtime dependencies
  astro-language-server,
  basedpyright,
  bash-language-server,
  biome,
  docker-compose-language-service,
  dockerfile-language-server,
  hadolint,
  lua-language-server,
  nixd,
  nixfmt,
  nurl,
  rubocop,
  ruff,
  rust-analyzer,
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
  yaml-language-server,
}:
let
  mapBuiltinPluginToPath = map (p: "$out/share/nvim/runtime/plugin/${p}");
  disabledBuiltinPluginPaths = mapBuiltinPluginToPath [
    "matchit.vim"
    "matchparen.vim"
    "netrwPlugin.vim"
    "tutor.vim"
  ];

  neovim-unwrapped' = neovim-unwrapped.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
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
    dockerfile-language-server
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
    nixfmt
    # python
    basedpyright
    ruff
    # ruby
    # solargraph
    rubocop
    # rust
    rust-analyzer
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
  ];

  extraWrapperArgs = [
    "--suffix"
    "PATH"
    ":"
    (lib.makeBinPath (language-servers ++ tools))
  ];

  # Prepend only the runtime config to the rtp, not the whole directory: the
  # co-located flake-parts module (default.nix) and package definitions share
  # this directory, and including them would make every Neovim rebuild on an
  # unrelated module edit and defeat the drvPath-equality verification.
  runtimeConfig = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./init.lua
      ./lsp
      ./lua
    ];
  };

in
wrapNeovimUnstable neovim-unwrapped' {
  withNodeJs = true; # for copilot
  withRuby = false;
  withPython3 = false;
  vimAlias = true;
  luaRcContent = ''
    vim.opt.rtp:prepend('${runtimeConfig}')

    ${builtins.readFile ./init.lua}
  '';

  plugins = import ./plugins.nix { inherit vimPlugins; };

  wrapperArgs = extraWrapperArgs;
}
