return {
  {
    name = "nvim-lspconfig",
    dir = "@nvim_lspconfig@",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(_, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set("n", "<space>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
        vim.keymap.set("n", "<leader>cf", function()
          vim.lsp.buf.format({ async = true })
        end, bufopts)
      end

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")

      for _, ls in pairs({
        "astro",
        "bashls",
        "nil_ls",
        "pyright",
        "rust_analyzer",
        "terraformls",
      }) do
        lspconfig[ls].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end
      lspconfig.dockerls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern("Dockerfile", "Containerfile"),
      })
      lspconfig.docker_compose_language_service.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern(
          "docker-compose.yaml",
          "docker-compose.yml",
          "compose.yaml",
          "compose.yml"
        ),
      })
      lspconfig.lua_ls.setup({
        on_attach = on_attach,
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
          null_ls.builtins.diagnostics.ruff,
          null_ls.builtins.diagnostics.shellcheck,
          null_ls.builtins.formatting.ruff,
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.alejandra,
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.shfmt,
          null_ls.builtins.code_actions.shellcheck,
        },
      })
    end,
  },
  {
    name = "lspsaga.nvim",
    dir = "@lspsaga_nvim@",
    event = "BufRead",
    config = true,
  },
}
