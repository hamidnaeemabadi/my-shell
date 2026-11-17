if vim.fn.has("nvim-0.11.3") == 0 then
    vim.notify("my-shell plugins require Neovim 0.11.3+; basic settings remain active", vim.log.levels.WARN)
    return
end

local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazy_path) then
    if vim.fn.executable("git") == 0 then
        vim.notify("Install git to download Neovim plugins", vim.log.levels.WARN)
        return
    end
    local output = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazy_path,
    })
    if vim.v.shell_error ~= 0 then
        vim.notify("Could not download lazy.nvim; restart Neovim to retry:\n" .. output, vim.log.levels.WARN)
        return
    end
end
vim.opt.rtp:prepend(lazy_path)
vim.g.mapleader = " "

vim.filetype.add({
    extension = { tf = "terraform" },
    pattern = {
        [".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
        [".*/roles/[^/]+/tasks/.*%.ya?ml"] = "yaml.ansible",
        [".*/roles/[^/]+/handlers/.*%.ya?ml"] = "yaml.ansible",
        [".*/templates/.*%.ya?ml"] = function(path)
            if #vim.fs.find("Chart.yaml", { path = vim.fs.dirname(path), upward = true }) > 0 then
                return "helm"
            end
        end,
    },
})

local servers = {
    bashls = "bash-language-server",
    yamlls = "yaml-language-server",
    terraformls = "terraform-ls",
    ansiblels = "ansible-language-server",
    dockerls = "docker-langserver",
    jsonls = "vscode-json-language-server",
}

vim.api.nvim_create_user_command("DevOpsTools", function()
    local tools = { "git", "rg", "fd", "shellcheck", "yamllint", "ansible-lint", "shfmt", "terraform", "prettier" }
    vim.list_extend(tools, vim.tbl_values(servers))
    table.sort(tools)
    local lines = {}
    for _, tool in ipairs(tools) do
        lines[#lines + 1] = (vim.fn.executable(tool) == 1 and "OK      " or "MISSING ") .. tool
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "DevOps tools" })
end, { desc = "Show installed language servers, linters and formatters" })

require("lazy").setup({
    {
        "neovim/nvim-lspconfig",
        config = function()
            -- nvim-lint owns ShellCheck and ansible-lint diagnostics.
            vim.lsp.config("bashls", { settings = { bashIde = { shellcheckPath = "" } } })
            vim.lsp.config("ansiblels", {
                settings = { ansible = { validation = { lint = { enabled = false } } } },
            })
            for server, command in pairs(servers) do
                if vim.fn.executable(command) == 1 then
                    vim.lsp.enable(server)
                end
            end
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("my_shell_lsp", { clear = true }),
                callback = function(event)
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client:supports_method("textDocument/completion") then
                        vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
                    end
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = event.buf, desc = "Go to definition" })
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = event.buf, desc = "Code action" })
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = event.buf, desc = "Rename symbol" })
                end,
            })
            vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Explain diagnostic" })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                sh = { "shellcheck" },
                bash = { "shellcheck" },
                yaml = { "yamllint" },
                ["yaml.ansible"] = { "yamllint", "ansible_lint" },
            }
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
                group = vim.api.nvim_create_augroup("my_shell_lint", { clear = true }),
                callback = function()
                    if vim.bo.buftype == "" then
                        lint.try_lint(nil, {
                            filter = function(linter)
                                return vim.fn.executable(linter.cmd) == 1
                            end,
                        })
                    end
                end,
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        lazy = false,
        opts = {
            formatters_by_ft = {
                sh = { "shfmt" },
                bash = { "shfmt" },
                terraform = { "terraform_fmt" },
                ["terraform-vars"] = { "terraform_fmt" },
                yaml = { "prettier" },
                ["yaml.ansible"] = { "prettier" },
                ["yaml.docker-compose"] = { "prettier" },
                json = { "prettier" },
                jsonc = { "prettier" },
            },
        },
        keys = {
            { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "never" }) end,
                mode = { "n", "v" }, desc = "Format buffer or selection" },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        lazy = false,
        opts = {},
        keys = {
            { "<leader>hp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview Git hunk" },
            { "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage Git hunk" },
            { "]h", function() require("gitsigns").nav_hunk("next") end, desc = "Next Git hunk" },
            { "[h", function() require("gitsigns").nav_hunk("prev") end, desc = "Previous Git hunk" },
        },
    },
    {
        "folke/snacks.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            picker = { enabled = true, sources = {
                files = { hidden = true, exclude = { ".git", ".terraform" } },
                grep = { hidden = true, exclude = { ".git", ".terraform" } },
            } },
            explorer = { enabled = true },
        },
        keys = {
            { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
            { "<leader>fg", function() Snacks.picker.grep() end, desc = "Search repository" },
            { "<leader>e", function() Snacks.explorer() end, desc = "File explorer" },
            { "<leader>xx", function() Snacks.picker.diagnostics() end, desc = "List diagnostics" },
        },
    },
}, {
    local_spec = false,
    checker = { enabled = false },
    change_detection = { notify = false },
})
