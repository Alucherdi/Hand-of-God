local M = {}

function M:create_window()

    local window = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        height = 12, width = 64,
        row = 0, col = 0
    })

end

return M
