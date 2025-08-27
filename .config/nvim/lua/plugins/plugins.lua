-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  {
    "williamboman/mason.nvim",
    opts = { ensure_installed = { "shellcheck", "prettier" } },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
        "ruff",
        "yamlls",
        "ruby_lsp",
        "helm_ls",
        "terraformls",
        "tflint",
        "jsonls",
      },
      servers = {
        on_new_config = function(new_config)
          new_config.settings.json.schemas = new_config.settings.json.schemas or {}
          vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
        end,
        settings = {
          json = {
            format = {
              enable = true,
            },
            validate = { enable = true },
          },
          shfmt = {
            extra_args = { "-i", "4" },
          },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
              },
            },
          },
        },
        jdtls = {},
      },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
      },
    },
  },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "terraform",
        "ruby",
        "hcl",
        "java",
      },
    },
  },

  -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
  -- would overwrite `ensure_installed` with the new value.
  -- If you'd rather extend the default config, use the code below instead:
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
      })
    end,
  },

  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local null_ls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        null_ls.builtins.formatting.opentofu_fmt,
        null_ls.builtins.diagnostics.opentofu_validate,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        tf = { "tfmt" },
        terraform = { "tfmt" },
        hcl = { "tfmt" },
        sh = { "shfmt" },
        python = { "ruff_format" },
      },
      formatters = {
        tfmt = {
          -- Specify the command and its arguments for formatting
          command = "tofu",
          args = { "fmt", "-" },
          stdin = true,
        },
        shfmt = {
          prepend_args = { "-i", "4", "ci" },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        hidden = true, -- for hidden files
        ignored = true, -- for .gitignore files
      },
    },
  },
  {
    "tpope/vim-fugitive",
  },
  {
    "PedramNavid/dbtpal",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    ft = {
      "sql",
      "md",
      "yaml",
    },
    keys = {
      { "<leader>drf", "<cmd>DbtRun<cr>" },
      { "<leader>drp", "<cmd>DbtRunAll<cr>" },
      { "<leader>dtf", "<cmd>DbtTest<cr>" },
      { "<leader>dm", "<cmd>lua require('dbtpal.telescope').dbt_picker()<cr>" },
    },
    config = function()
      require("dbtpal").setup({
        path_to_dbt = "dbt",
        path_to_dbt_project = "",
        path_to_dbt_profiles_dir = vim.fn.expand("~/.dbt"),
        include_profiles_dir = true,
        include_project_dir = true,
        include_log_level = true,
        extended_path_search = true,
        protect_compiled_files = true,
        pre_cmd_args = {},
        post_cmd_args = {},
      })
      require("telescope").load_extension("dbtpal")
    end,
  },
}
