local M = {}

function M:create_window(title, buf)
    local window = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        title = title,
        border = 'single',
        title_pos = 'center',
        height = 12, width = 64,
        row = 0, col = 0
    })

    return window
end

return M
