local commons = require('handofgod.commons')
local M = {}

function M.spawn(name, path, callback)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {name})

    local win = commons:create_window('Rename', buf, {
        style = 'minimal',
        width = #name + 8, height = 1,
        row = 1, col = 1
    })

    vim.keymap.set('n', 'q', function()
        local new_name = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        print(path .. new_name)

        vim.fn.rename(
            path .. name,
            path .. new_name
        )

        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, { force = true })

        callback()
    end, {buffer=buf})
end

return M
