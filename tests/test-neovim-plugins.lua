local ok, err = pcall(function()
    assert(vim.v.errmsg == "", vim.v.errmsg)
    local plugins = require("lazy.core.config").plugins
    for _, name in ipairs({ "nvim-lspconfig", "nvim-lint", "conform.nvim", "gitsigns.nvim", "snacks.nvim" }) do
        assert(plugins[name] and plugins[name]._.loaded, name .. " did not load")
    end
    local conform = require("conform")
    local lint = require("lint")
    assert(vim.fn.exists(":DevOpsTools") == 2)
    vim.cmd("DevOpsTools")
    assert(vim.fn.maparg("<Space>ff", "n") ~= "")
    assert(vim.fn.maparg("<Space>cf", "n") ~= "")
    assert(vim.fn.maparg("<Space>hp", "n") ~= "")
    assert(vim.lsp.config.bashls.settings.bashIde.shellcheckPath == "")
    assert(not vim.lsp.config.ansiblels.settings.ansible.validation.lint.enabled)

    local root = vim.env.MY_SHELL_TEST_ROOT
    vim.cmd("edit " .. vim.fn.fnameescape(root .. "/test.sh"))
    assert(vim.bo.filetype == "sh")
    assert(lint.linters_by_ft.sh[1] == "shellcheck")
    assert(conform.formatters_by_ft.sh[1] == "shfmt")
    -- Missing executables should not cause lint autocmd errors.
    local executable = vim.fn.executable
    vim.fn.executable = function() return 0 end
    vim.api.nvim_exec_autocmds("BufWritePost", { buffer = 0 })
    vim.fn.executable = executable
    if executable("shellcheck") == 1 then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "#!/bin/sh", "echo $1" })
        lint.try_lint("shellcheck")
        assert(vim.wait(5000, function()
            return #vim.diagnostic.get(0, { namespace = lint.get_namespace("shellcheck") }) > 0
        end), "ShellCheck did not report the unquoted argument")
    end

    vim.cmd("edit! " .. vim.fn.fnameescape(root .. "/config.yaml"))
    assert(vim.bo.filetype == "yaml" and vim.bo.shiftwidth == 2)
    assert(conform.formatters_by_ft.yaml[1] == "prettier")
    vim.cmd("edit " .. vim.fn.fnameescape(root .. "/roles/web/tasks/main.yml"))
    assert(vim.bo.filetype == "yaml.ansible")
    assert(vim.tbl_contains(lint.linters_by_ft[vim.bo.filetype], "ansible_lint"))
    assert(vim.bo.shiftwidth == 2)

    vim.fn.mkdir(root .. "/chart/templates", "p")
    vim.fn.writefile({ "apiVersion: v2", "name: test", "version: 0.1.0" }, root .. "/chart/Chart.yaml")
    vim.cmd("edit " .. vim.fn.fnameescape(root .. "/chart/templates/deployment.yaml"))
    assert(vim.bo.filetype == "helm")
    assert(not conform.formatters_by_ft.helm)
    assert(not lint.linters_by_ft.helm)
    vim.cmd("edit " .. vim.fn.fnameescape(root .. "/plain/templates/config.yaml"))
    assert(vim.bo.filetype == "yaml")
    if executable("terraform") == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(root .. "/main.tf"))
        assert(vim.bo.filetype == "terraform", "Unexpected Terraform filetype: " .. vim.bo.filetype)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "locals { answer=42 }" })
        conform.format({ async = false, timeout_ms = 3000, lsp_format = "never" }, function(format_error)
            assert(not format_error, vim.inspect(format_error))
        end)
        assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("answer = 42", 1, true))
    end
    assert(vim.v.errmsg == "", vim.v.errmsg)
end)
if not ok then
    io.stderr:write(tostring(err) .. "\n")
    vim.cmd("cquit")
else
    print("All five Neovim plugins and DevOps configuration checks passed")
    vim.cmd("qa!")
end
