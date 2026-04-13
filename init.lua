-------------------------------------------------------------------------------
-- Enable byte-code caching
-------------------------------------------------------------------------------
if vim.loader then
   vim.loader.enable()
end

-------------------------------------------------------------------------------
-- Options
-------------------------------------------------------------------------------
vim.opt.background = "dark"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldnestmax = 10
vim.opt.hlsearch = true
vim.opt.inccommand = "split"
vim.opt.listchars = { -- special characters
   -- eol = "⏎",
   -- space = "␣",
   tab = ">-",
   trail = "⋅",
   nbsp = "~",
   extends = ">",
   precedes = "<",
}
vim.opt.list = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.shiftwidth = 4
vim.opt.signcolumn = "yes:1"
vim.opt.spell = true
vim.opt.spelllang = "en_ca"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.virtualedit = "block"
vim.opt.winborder = "rounded"

vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.vimtex_view_method = "sioyek"

vim.diagnostic.config({
   virtual_text = {
      current_line = true,
   },
})

-------------------------------------------------------------------------------
-- vim.pack install hooks, https://neovim.io/doc/user/pack/#vim.pack-events
-------------------------------------------------------------------------------
---@param ev vim.api.keyset.create_autocmd.callback_args
local function install_pack_hooks(ev)
   -- Use available |event-data|
   local name, kind = ev.data.spec.name, ev.data.kind
   -- Run build script after plugin's code has changed
   if name == "blink.cmp" and (kind == "install" or kind == "update") then
      local plugin_path = ev.data.path
      -- Check if cargo is available
      if vim.fn.executable("cargo") == 1 then
         vim.notify("[blink.cmp] Compiling Rust binary...", vim.log.levels.INFO)
         -- Run the build command inside the plugin directory
         local obj = vim.system(
            { "cargo", "build", "--release" },
            { cwd = plugin_path }
         )
            :wait()
         -- Output build status
         if obj.code == 0 then
            vim.notify("[blink.cmp] Build complete.", vim.log.levels.INFO)
         else
            vim.notify(
               "[blink.cmp] Build failed:\n" .. obj.stderr,
               vim.log.levels.ERROR
            )
         end
      end
   end
end

-- If hooks need to run on install, run this before `vim.pack.add()`
-- To act on install from lockfile, run before very first `vim.pack.add()`
local pack_grp = vim.api.nvim_create_augroup("Pack", { clear = true })
vim.api.nvim_create_autocmd("PackChanged", {
   group = pack_grp,
   desc = "Install vim.pack hooks",
   callback = install_pack_hooks,
})

-------------------------------------------------------------------------------
-- Plugins (vim.pack)
-------------------------------------------------------------------------------
vim.pack.add({
   -- Core
   "https://github.com/saghen/blink.cmp", -- auto completion
   "https://github.com/ibhagwan/fzf-lua", -- fuzzy finding, requires fzf
   "https://github.com/rebelot/kanagawa.nvim", -- colour scheme
   "https://github.com/nvim-lualine/lualine.nvim", -- status line
   "https://github.com/christoomey/vim-tmux-navigator", -- seamless navigation between Neovim and tmux panes
   "https://github.com/folke/which-key.nvim", -- keybinding helper (shows available mappings in a popup)

   -- LSP
   "https://github.com/mason-org/mason.nvim", -- installs formatters and linters, requires Node.js
   "https://github.com/mason-org/mason-lspconfig.nvim", -- installs and enables language servers
   "https://github.com/neovim/nvim-lspconfig", -- auto-configures language servers

   -- Formatting and linting
   "https://github.com/stevearc/conform.nvim", -- formatter
   "https://github.com/mfussenegger/nvim-lint", -- linter

   -- Enhances Neovim config development (Lua LSP, typings, etc.)
   -- "https://github.com/folke/lazydev.nvim",
}, { confirm = false })

-- Enable native Undotree
vim.cmd("packadd nvim.undotree")

-------------------------------------------------------------------------------
-- vim.pack custom commands
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command("PackClean", function()
   local inactive_plugins = vim.iter(vim.pack.get())
      :filter(function(x)
         return not x.active
      end)
      :map(function(x)
         return x.spec.name
      end)
      :totable()

   if #inactive_plugins > 0 then
      vim.pack.del(inactive_plugins)
      vim.notify(
         "Removed inactive plugins: " .. table.concat(inactive_plugins, ", ")
      )
   else
      vim.notify("No inactive plugins to remove")
   end
end, {
   desc = "Remove inactive vim.pack plugins",
})

vim.api.nvim_create_user_command("PackSync", function()
   vim.pack.update(nil, { target = "lockfile" })
end, {
   desc = "Sync vim.pack plugins to lockfile (nvim-pack-lock.json)",
})

vim.api.nvim_create_user_command("PackUpdate", function()
   vim.pack.update()
end, {
   desc = "Update vim.pack plugins",
})

-------------------------------------------------------------------------------
-- Plugin configurations
-------------------------------------------------------------------------------
-- blink.cmp
require("blink.cmp").setup({
   completion = {
      menu = {
         border = "rounded",
         draw = {
            columns = {
               { "label", "label_description", gap = 1 },
               { "kind_icon", "kind", "source_name", gap = 1 },
            },
         },
      },
      documentation = {
         auto_show = true,
         window = {
            border = "rounded",
            scrollbar = true,
            winhighlight = table.concat({
               "Normal:BlinkCmpMenu",
               "NormalFloat:BlinkCmpMenu",
               "FloatBorder:BlinkCmpMenuBorder",
               "CursorLine:BlinkCmpDocCursorLine",
               "Search:None",
            }, ","),
         },
      },
   },
   fuzzy = {
      implementation = vim.fn.executable("cargo") == 1 and "prefer_rust"
         or "lua",
   },
   keymap = { ["<CR>"] = { "accept", "fallback" } },
   signature = {
      enabled = true,
      window = { border = "rounded" },
   },
   cmdline = { completion = { menu = { auto_show = true } } },
})

-- fzf-lua
local fzf = require("fzf-lua")
fzf.setup({
   keymap = {
      fzf = {
         -- Map <C-q> to select all items and press enter
         ["ctrl-q"] = "select-all+accept",
      },
   },
})
fzf.register_ui_select()
vim.keymap.set(
   "n",
   "<leader>co",
   "<cmd>FzfLua colorschemes<CR>",
   { desc = "Color schemes", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>fb",
   "<cmd>FzfLua buffers<CR>",
   { desc = "Find buffers", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>ff",
   "<cmd>FzfLua files<CR>",
   { desc = "Find files", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>fg",
   "<cmd>FzfLua grep_project<CR>",
   { desc = "Grep project", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>fo",
   "<cmd>FzfLua oldfiles<CR>",
   { desc = "File history", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>fi",
   "<cmd>FzfLua git_files<CR>",
   { desc = "Find git files", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>fr",
   "<cmd>FzfLua lsp_references<CR>",
   { desc = "LSP references", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>xX",
   "<cmd>FzfLua diagnostics_document<CR>",
   { desc = "Diagnostics document", silent = true }
)
vim.keymap.set(
   "n",
   "<leader>xx",
   "<cmd>FzfLua diagnostics_workspace<CR>",
   { desc = "Diagnostics project", silent = true }
)

-- kanagawa
require("kanagawa").setup({
   -- Remove the background of LineNr, {Sign,Fold}Column and friends
   colors = {
      theme = {
         all = {
            ui = {
               bg_gutter = "none",
            },
         },
      },
   },
})

-- lualine.nvim
require("lualine").setup({})

-- mason.nvim
local formatters = {
   "black", -- Python
   "gofumpt", -- Go
   "goimports", -- Go
   "golines", -- Go
   "latexindent", -- Latex
   "prettier", -- Multiple languages
   "shfmt", -- Bash/sh
   "stylua", -- Lua
}
local linters = {
   "cmakelang", -- CMake
   "cmakelint", -- CMake
   "mypy", -- Python
   "shellcheck", -- Bash/sh
}

--- Ensures the given Mason packages are installed, installing any missing ones
--- asynchronously
---@param tools string[]  -- List of Mason package names to ensure installed
local function ensure_mason_tools_installed(tools)
   local mr = require("mason-registry")
   mr.refresh(function()
      for _, tool in ipairs(tools) do
         local ok, pkg = pcall(mr.get_package, tool)
         if ok and not pkg:is_installed() then
            pkg:install()
         end
      end
   end)
end

require("mason").setup({
   ui = { border = "rounded" },
})
ensure_mason_tools_installed(formatters)
ensure_mason_tools_installed(linters)

-- mason-lspconfig.nvim
local language_servers = {
   "basedpyright",
   "bashls",
   "clangd",
   "cmake",
   "eslint",
   "gopls",
   "julials",
   "lua_ls",
   "marksman",
   "perlnavigator",
   "ruff",
   "rust_analyzer",
   "texlab",
   "tinymist",
   "tombi",
   "ts_ls",
   "vimls",
   "yamlls",
   "zls",
}
require("mason-lspconfig").setup({
   ensure_installed = language_servers,
   automatic_enable = {
      exclude = { "julials" },
   },
})
vim.lsp.enable("julials")

-- conform.nvim
require("conform").setup({
   formatters_by_ft = {
      cmake = { "cmakelang" },
      go = { "golines", "gofumpt", "goimports" },
      javascript = { "prettier" },
      json = { "prettier" },
      lua = { "stylua" },
      markdown = { "prettier" },
      python = { "black" },
      sh = { "shfmt" },
      typescript = { "prettier" },
   },
   format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true, -- use LSP if no formatter
   },
})
vim.keymap.set("n", "<leader>fm", function()
   require("conform").format()
end, { desc = "Format buffer (conform.nvim)", silent = true })

-- nvim-lint
require("lint").linters_by_ft = {
   bash = { "shellcheck" },
   cmake = { "cmakelint" },
   python = { "mypy" },
}
local nvim_lint_grp = vim.api.nvim_create_augroup("Nvim-lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
   group = nvim_lint_grp,
   desc = "nvim-lint hooks",
   callback = function()
      -- try_lint without arguments runs the linters defined in `linters_by_ft`
      -- for the current filetype
      require("lint").try_lint()
      -- You can call `try_lint` with a linter name or a list of names to
      -- always run specific linters, independent of the `linters_by_ft`
      -- configuration
      -- require("lint").try_lint("cspell")
   end,
})

-------------------------------------------------------------------------------
-- Auto commands
-------------------------------------------------------------------------------
local generic_grp = vim.api.nvim_create_augroup("Generic", { clear = true })

-- Set SignColumn colour to background colour, aesthetically nicer
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
   group = generic_grp,
   pattern = { "*" },
   desc = "Set SignColumn color to background color",
   command = "hi! link SignColumn Normal",
})

-- Disable spell in terminal buffers
vim.api.nvim_create_autocmd("TermOpen", {
   group = generic_grp,
   desc = "Disable spell in terminal buffers",
   callback = function()
      vim.opt_local.spell = false
   end,
})

-- Highlights yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
   group = generic_grp,
   pattern = { "*" },
   desc = "Highlights yanked text",
   callback = function()
      vim.highlight.on_yank({ timeout = 200 })
   end,
})

-------------------------------------------------------------------------------
-- Generic keymaps
-------------------------------------------------------------------------------
vim.keymap.set("n", "<ESC>", "<cmd>nohlsearch<CR>", { silent = true })
vim.keymap.set(
   "n",
   "<leader>e",
   "<cmd>Lexplore 25<CR>",
   { desc = "Netrw file explorer", silent = true }
)
vim.keymap.set("n", "<leader>u", function()
   require("undotree").open({
      command = "topleft 30vnew",
   })
end, { desc = "Undotree toggle", silent = true })

local lsp_grp = vim.api.nvim_create_augroup("LspKeymaps", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
   group = lsp_grp,
   desc = "LSP keymaps",
   callback = function(ev)
      vim.keymap.set(
         "n",
         "gd",
         vim.lsp.buf.definition,
         { desc = "LSP go to definition", silent = true }
      )
      vim.keymap.set(
         "n",
         "gD",
         vim.lsp.buf.declaration,
         { desc = "LSP go to declaration", silent = true }
      )
      vim.keymap.set("n", "<leader>ih", function()
         local enabled = vim.lsp.inlay_hint.is_enabled()
         local new = not enabled
         vim.lsp.inlay_hint.enable(new)
         vim.notify(
            "Inlay hints (global): " .. (new and "enabled" or "disabled"),
            vim.log.levels.INFO,
            { title = "LSP" }
         )
      end, { desc = "Toggle inlay hints (global)" })
      vim.keymap.set("n", "<leader>iH", function()
         local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
         local new = not enabled
         vim.lsp.inlay_hint.enable(new, { bufnr = ev.buf })
         vim.notify(
            "Inlay hints (buffer): " .. (new and "enabled" or "disabled"),
            vim.log.levels.INFO,
            { title = "LSP" }
         )
      end, { buffer = ev.buf, desc = "Toggle inlay hints (buffer)" })
   end,
})

-------------------------------------------------------------------------------
-- UI
-------------------------------------------------------------------------------
-- Enable new experimental UI2
require("vim._core.ui2").enable({
   enable = true,
   msg = {
      -- This redirect messages to the new system
      targets = {
         confirm = "cmd", -- Confirm prompts (e.g., :quit with unsaved changes)
         [""] = "msg", -- General messages (echo)
         bufwrite = "msg", -- Buffer write messages
         echo = "msg", -- :echo output
         echoerr = "msg", -- :echoerr output
         echomsg = "msg", -- :echomsg output
         emsg = "msg", -- Error messages (goes to the new pager buffer)
      },
   },
})

-- Set colour scheme
vim.cmd.colorscheme("kanagawa")
