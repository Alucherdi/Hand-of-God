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

function M.close(mod)
    if not mod then return end
    local wv = vim.api.nvim_win_is_valid(mod.win)
    local bv = vim.api.nvim_buf_is_valid(mod.buf)

    if wv and bv then
        vim.api.nvim_win_close(mod.win, true)
        vim.api.nvim_buf_delete(mod.buf, { force = true })
    end

    mod.win = nil
    mod.buf = nil
    mod.is_active = false
end

return M
