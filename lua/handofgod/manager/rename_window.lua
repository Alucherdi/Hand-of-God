local M = {}

function M.spawn(name, path, callback)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {name})

    local w = #name * 2
    local h = 1

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        title = 'Rename',
        title_pos = 'center',
        border = 'single',
        style = 'minimal',
        width = w, height = h,
        col = 0, row = 0
    })

    vim.keymap.set({'n', 'i'}, '<Esc>', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, { force = true })
    end, {buffer = buf})

    vim.keymap.set('n', 'q', function()
        local new_name = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]

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
