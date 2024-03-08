return {
  {
    name = "nvim-lspconfig",
    dir = "@nvim_lspconfig@",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
      vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          -- Mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set("n", "<space>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")

      for _, ls in pairs({
        "astro",
        "bashls",
        "biome",
        "nil_ls",
        "pyright",
        "ruff_lsp",
        "rubocop",
        "rust_analyzer",
        "solargraph",
        "taplo",
        "terraformls",
        "tsserver",
        "yamlls"
      }) do
        lspconfig[ls].setup({
          capabilities = capabilities,
        })
      end
      lspconfig.dockerls.setup({
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern("Dockerfile", "Containerfile"),
      })
      lspconfig.docker_compose_language_service.setup({
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern(
          "docker-compose.yaml",
          "docker-compose.yml",
          "compose.yaml",
          "compose.yml"
        ),
      })
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })
    end,
  },
  {
    name = "none-ls.nvim",
    dir = "@none_ls_nvim@",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          null_ls.builtins.diagnostics.hadolint,
          null_ls.builtins.formatting.nixfmt,
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.shfmt,
        },
      })
    end,
  },
  {
    name = "lspsaga.nvim",
    dir = "@lspsaga_nvim@",
    event = "BufRead",
    config = function()
      require("lspsaga").setup({
        lightbulb = {
          sign = false,
        },
      })
    end,
  },
}
