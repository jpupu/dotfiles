-- Bootstrap plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)


vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10


-- Make sure to set map leader before loading plugins
vim.g.mapleader = " "

-- Load plugins
require("lazy").setup({
	{ 'echasnovski/mini.nvim',           version = '0.8' },

	-- Manages external tools such as LSP servers, DAP servers,
	-- linters and formatters
	{
		'williamboman/mason.nvim',
		config = true,
		build = ":MasonUpdate" -- :MasonUpdate updates registry contents
	},
	{
		'williamboman/mason-lspconfig',
		config = true,
		build = ":MasonUpdate" -- :MasonUpdate updates registry contents
	},

	{
		'folke/neodev.nvim',
		config = true, -- IMPORTANT: make sure to setup neodev BEFORE lspconfig
	},
	'neovim/nvim-lspconfig',

	'hrsh7th/cmp-nvim-lsp',
	'hrsh7th/cmp-buffer',
	'hrsh7th/cmp-path',
	'hrsh7th/nvim-cmp',
	'hrsh7th/cmp-vsnip',
	'hrsh7th/vim-vsnip',

	{
		'folke/which-key.nvim',
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({})
		end,
	},

	{ 'nvim-treesitter/nvim-treesitter', build = ":TSUpdate" },

	-- Jump quickly with s-<letter>-<letter>
	'ggandor/leap.nvim',

	{ 'lewis6991/gitsigns.nvim',       config = true },
	{ 'nvim-tree/nvim-web-devicons',   config = true },
	{ 'nvim-telescope/telescope.nvim', tag = '0.1.1', dependencies = { 'nvim-lua/plenary.nvim' }, },

	{ name="aika", dir = "/home/artham/.config/nvim/aika" }
})

require('leap').add_default_mappings()
require('mini.basics').setup({})
require('mini.comment').setup({})
require('mini.bracketed').setup({})
require('mini.statusline').setup({})

require('lspconfig').pyright.setup {}
require('lspconfig').clangd.setup {
}
require('lspconfig').lua_ls.setup {}

local colorscheme = "minischeme"
local ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not ok then
	vim.notify("colorscheme " .. colorscheme .. " not found!")
end


-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		local tsb = require('telescope.builtin')
		-- local wk = require('which-key')
		local function mapkey(mode, key, action, desc)
			opts = { buffer = ev.buf, desc = "[LSP] " .. desc }
			vim.keymap.set(mode, key, action, opts)
		end

		-- wk.register({
		-- 	g = {
		-- 		z = {
		-- 			name = "+LSP",
		-- 			r = { tsb.lsp_references, "List references" }
		-- 		}
		-- 	}
		-- })
		-- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
		-- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
		-- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
		-- vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
		-- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
		mapkey('n', 'gd', tsb.lsp_definitions, "Goto definitions")
		mapkey('n', 'gi', tsb.lsp_implementations, "Goto implementation")
		mapkey('n', 'gt', tsb.lsp_type_definitions, "Goto type definition")
		mapkey('n', 'gr', tsb.lsp_references, "Goto references")

		vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
		vim.keymap.set({ 'n', 'i' }, '<C-k>', vim.lsp.buf.signature_help, opts)
		vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, opts)
		vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
		vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, opts)
		vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
	end,
})


-- require('mini.completion').setup({})
local has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end
local cmp = require('cmp')
cmp.setup({
	completion = { autocomplete = false, },
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		['<C-k>'] = cmp.mapping.select_prev_item(),
		['<C-j>'] = cmp.mapping.select_next_item(),
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.abort(),
		-- ['<Tab>'] = cmp.mapping.confirm({ select = true }),
		['<Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.confirm({ select = true })
			elseif has_words_before() then
				cmp.complete()
				if #cmp.get_entries() == 1 then
					cmp.confirm({ select = true })
				end
			else
				fallback()
			end
		end, {"i", "s"}),
		['<Bs>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				print(vim.inspect(#cmp.get_entries()))	
			else
				fallback()
			end
		end),
	}),
	sources = cmp.config.sources({
		{ name = 'nvim_lsp',
		  entry_filter = function(entry, ctx)
			  if string.find(entry:get_insert_text(), "::") then
				  return false
			  end
			  -- print(entry:is_available(), entry:get_debug_name())
			  return true
		  end,},
		-- { name = 'nvim_cmp_text', priority = -1 },
		{ name = 'buffer', priority = -1 },
	}),
})

-- cmp.setup.cmdline({'/', '?'},{
-- 	mapping = cmp.mapping.preset.cmdline(),
-- 	sources = { {name='buffer'}}})

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- This stops completion from pasting the whole function sinature
-- with paremeter types and names.
capabilities.textDocument.completion.completionItem.snippetSupport = false;

require('lspconfig')['pyright'].setup {
	capabilities = capabilities
}
require('lspconfig')['clangd'].setup {
	capabilities = capabilities,
	-- cmd={
	--     "clangd",
	--     "--background-index",
	--     "-j=4",
	--     "--query-driver=/usr/bin/**/clang-*,/bin/clang,/bin/clang++,/usr/bin/gcc,/usr/bin/g++",
	--     "--clang-tidy",
	--     "--clang-tidy-checks=*",
	--     -- "--all-scopes-completion",
	--     "--cross-file-rename",
	--     "--completion-style=detailed",
	--     "--header-insertion-decorators",
	--     "--header-insertion=iwyu",
	--     "--pch-storage=memory",
	-- }
}


-- vim.keymap.set('n', '<leader>h', , opts)
vim.api.nvim_set_keymap('n', '<Leader>h', ':ClangdSwitchSourceHeader<CR>', { noremap = true, desc = "Switch cpp/hpp" })

require('nvim-treesitter.configs').setup({
	ensure_installed = { "lua", "vim", "vimdoc", "query", "c", "cpp", "rust" },
	highlight = {
		enable = true,
	},
})


-- How does mini.fuzzy differ from telescope default sorter?
-- require('telescope').setup({
-- 	defaults = { generic_sorter = require('mini.fuzzy').get_telescope_sorter },
-- })
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = "Find word in files (fuzzy)" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Find word in files (regex)" })
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = "Find previously open files" })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find buffer" })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find file" })
vim.keymap.set('n', '<leader>fF', function()
	builtin.find_files({ hidden = true, no_ignore = true, no_ignore_parent = true })
end, { desc = "Find file (no ignores)" })

vim.keymap.set('n', '[h', "<Cmd>Gitsigns prev_hunk<CR>")
vim.keymap.set('n', ']h', "<Cmd>Gitsigns next_hunk<CR>")
vim.keymap.set('n', ']e', function() vim.diagnostic.goto_next({severity=vim.diagnostic.severity.ERROR}) end)
vim.keymap.set('n', '[e', function() vim.diagnostic.goto_prev({severity=vim.diagnostic.severity.ERROR}) end)
vim.keymap.set('n', '<leader>cb', "<Cmd>Gitsigns blame_line<CR>")


local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end


vim.api.nvim_create_autocmd("FileType", {
	pattern = "cpp",
	command = "setlocal commentstring=//%s",
})
