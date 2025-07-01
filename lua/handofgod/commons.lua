local M = {
    separator = '[HOG_SEP]'
}

function M:create_window(title, buf, opts)
    local options = opts or {}

    local size = {
        width = options.width or 60,
        height = options.height or 30
    }

    local offset = {
        x = (vim.o.columns / 2) - (size.width / 2),
        y = math.ceil(vim.o.lines / 2) - math.ceil(size.height / 2),
    }

    local default = {
        relative = 'editor',
        title = title,
        border = 'single',
        title_pos = 'center',
        height = size.height,
        width = size.width,
        row = offset.y,
        col = offset.x
    }

    local opts

    if options then
        opts = vim.tbl_extend('force', default, options)
    else
        opts = default
    end

    local window = vim.api.nvim_open_win(buf, true, opts)

    return window, offset, size
end

function M.close(mod)
    if not mod or not mod.win or not mod.buf then
        return
    end

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
