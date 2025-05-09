local M = {}

function M:create_window(title, buf, options)
    local default = {
        relative = 'editor',
        title = title,
        border = 'single',
        title_pos = 'center',
        height = 12, width = 64,
        row = 0, col = 0
    }

    local opts

    if options then
        opts = vim.tbl_extend('force', default, options)
    else
        opts = default
    end

    local window = vim.api.nvim_open_win(buf, true, opts)

    return window
end

return M
