return {
  {
    name = "lualine.nvim",
    dir = "@lualine_nvim@",
    config = function()
      require("lualine").setup({
        options = {
          theme = "nord",
          globalstatus = true,
        },
      })
    end,
    event = "VeryLazy",
  },
  {
    name = "bufferline.nvim",
    dir = "@bufferline_nvim@",
    dependencies = { { name = "nvim-web-devicons", dir = "@nvim_web_devicons@" } },
    config = function()
      local highlights = require("nord").bufferline.highlights({
        italic = true,
        bold = true,
      })

      require("bufferline").setup({
        options = {
          separator_style = "thin",
        },
        highlights = highlights,
      })
    end,
    event = "VeryLazy",
  },
  {
    name = "noice.nvim",
    dir = "@noice_nvim@",
    event = "VeryLazy",
    dependencies = {
      { name = "nui.nvim",    dir = "@nui_nvim@" },
      { name = "nvim-notify", dir = "@nvim_notify@" },
    },
    config = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
      })
    end,
  },
  {
    name = "dressing.nvim",
    dir = "@dressing_nvim@",
    event = "VeryLazy",
  },
}
