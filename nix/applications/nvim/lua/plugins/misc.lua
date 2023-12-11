return {
  {
    name = "nord.nvim",
    dir = "@nord_nvim@",
    config = function()
      vim.g.nord_contrast = true
      vim.g.nord_italic = false
      require("nord").set()
    end,
    lazy = false,
  },
  {
    name = "neo-tree.nvim",
    dir = "@neo_tree_nvim@",
    dependencies = {
      { name = "nui.nvim",          dir = "@nui_nvim@" },
      { name = "nvim-web-devicons", dir = "@nvim_web_devicons@" },
      { name = "plenary.nvim",      dir = "@plenary_nvim@" },
    },
    cmd = { "Neotree" },
    init = function()
      vim.g.neo_tree_remove_legacy_commands = 1
    end,
    config = true,
  },
  {
    name = "telescope.nvim",
    dir = "@telescope_nvim@",
    dependencies = { name = "plenary.nvim", dir = "@plenary_nvim@" },
    cmd = "Telescope",
    keys = { "<leader>f" },
    config = function()
      local telescope = require("telescope")
      local trouble = require("trouble.providers.telescope")
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

      telescope.setup({
        defaults = {
          mappings = {
            i = { ["<c-t>"] = trouble.open_with_trouble },
            n = { ["<c-t>"] = trouble.open_with_trouble },
          },
        },
      })
    end,
  },
  {
    name = "flit.nvim",
    dir = "@flit_nvim@",
    keys = function()
      local ret = {}
      for _, key in ipairs({ "f", "f", "t", "t" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
      end
      return ret
    end,
    opts = { labeled_modes = "nx" },
  },
  {
    name = "leap.nvim",
    dir = "@leap_nvim@",
    keys = {
      { "s",  mode = { "n", "x", "o" }, desc = "Leap forward to" },
      { "S",  mode = { "n", "x", "o" }, desc = "Leap backward to" },
      { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      leap.add_default_mappings(true)
      vim.keymap.del({ "x", "o" }, "x")
      vim.keymap.del({ "x", "o" }, "X")
    end,
  },
  {
    name = "nvim-treesitter",
    dir = "@nvim_treesitter@",
    dependencies = {
      { name = "nvim-ts-rainbow2", dir = "@nvim_ts_rainbow2@" },
    },
    config = function()
      vim.opt.runtimepath:append("@ts_parser_dirs@")
      require("nvim-treesitter.configs").setup({
        highlight = {
          enable = true,
        },
        rainbow = {
          enable = true,
          query = "rainbow-parens",
          strategy = require("ts-rainbow").strategy.global,
        },
      })
    end,
    event = "BufRead",
  },
  {
    name = "nvim-surround",
    dir = "@nvim_surround@",
    config = true,
    event = "VeryLazy",
  },
  {
    name = "trouble.nvim",
    dir = "@trouble_nvim@",
    config = true,
    cmd = "Trouble",
  },
  {
    name = "which-key.nvim",
    dir = "@which_key_nvim@",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      require("which-key").setup({})
    end,
    event = "VeryLazy",
  },
  {
    name = "todo-comments.nvim",
    dir = "@todo_comments_nvim@",
    config = true,
    event = "BufRead",
  },
  {
    name = "gitsigns.nvim",
    dir = "@gitsigns_nvim@",
    config = function()
      require("gitsigns").setup({
        current_line_blame = true,
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true })

          -- Actions
          map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>")
          map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>")
          map("n", "<leader>hS", gs.stage_buffer)
          map("n", "<leader>hu", gs.undo_stage_hunk)
          map("n", "<leader>hR", gs.reset_buffer)
          map("n", "<leader>hp", gs.preview_hunk)
          map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
          end)
          map("n", "<leader>tb", gs.toggle_current_line_blame)
          map("n", "<leader>hd", gs.diffthis)
          map("n", "<leader>hD", function()
            gs.diffthis("~")
          end)
          map("n", "<leader>td", gs.toggle_deleted)

          -- Text object
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
        end,
      })
    end,
    event = "BufRead",
  },
  {
    name = "diffview.nvim",
    dir = "@diffview_nvim@",
    dependencies = { { name = "plenary.nvim", dir = "@plenary_nvim@" } },
    config = true,
    event = "VeryLazy",
  },
  {
    name = "octo.nvim",
    dir = "@octo_nvim@",
    dependencies = {
      { name = "plenary.nvim",      dir = "@plenary_nvim@" },
      { name = "telescope.nvim",    dir = "@telescope_nvim@" },
      { name = "nvim-web-devicons", dir = "@nvim_web_devicons@" },
    },
    event = "VeryLazy",
    config = function()
      require("octo").setup({
        ssh_aliases = { ["github.com-emu"] = "github.com" },
      })
    end,
  },
  {
    name = "indent-blankline.nvim",
    dir = "@indent_blankline_nvim@",
    event = "VeryLazy",
    main = "ibl",
    config = true,
  },
  {
    name = "Comment.nvim",
    dir = "@comment_nvim@",
    event = "BufRead",
    config = true,
  },
  {
    name = "vim-illuminate",
    dir = "@vim_illuminate@",
    event = "VeryLazy",
  },
  {
    name = "overseer.nvim",
    dir = "@overseer_nvim@",
    cmd = { "OverseerRun", "OverseerToggle" },
    config = true,
  },
  {
    name = "ChatGPT.nvim",
    dir = "@chatgpt_nvim@",
    dependencies = {
      { name = "nui.nvim",       dir = "@nui_nvim@" },
      { name = "plenary.nvim",   dir = "@plenary_nvim@" },
      { name = "telescope.nvim", dir = "@telescope_nvim@" },
    },
    cmd = {
      "ChatGPT",
      "ChatGPTActAs",
      "ChatGPTEditWithInstructions",
      "ChatGPTRun",
    },
    config = function()
      require("chatgpt").setup({
        openai_params = {
          model = "gpt-4-1106-preview",
        },
        openai_edit_params = {
          model = "gpt-4-1106-preview",
        },
        api_key_cmd = "rbw get OPENAI_API_KEY",
      })
    end,
  },
  {
    name = "markdown-preview.nvim",
    dir = "@markdown_preview_nvim@",
    ft = "markdown",
    keys = { "<Leader>mp" },
    config = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")
    end,
  },
  {
    name = "vim-pydocstring",
    dir = "@vim_pydocstring@",
    ft = "python",
    config = function()
      vim.g.pydocstring_formatter = "google"
    end,
  },
  {
    name = "nvim-autopairs",
    dir = "@nvim_autopairs@",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      npairs.setup({})
    end,
  },
}
