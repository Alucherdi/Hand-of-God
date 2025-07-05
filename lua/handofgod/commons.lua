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

function M.set_icons(buf, paths, ns, current_path)
    local mini_icons = _G.MiniIcons
    if not mini_icons then
        print('No setup for MiniIcons found')
        return
    end

    if not current_path then
        current_path = vim.fn.expand('%:p:h')
    end

    local id = vim.api.del
    if #paths == 0 then
        local extmarks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
        for i, v in ipairs(extmarks) do
            vim.api.nvim_buf_del_extmark(buf, ns, v[1])
        end
    end

    for i, v in ipairs(paths) do
        local icon, hl
        local name = vim.fn.fnamemodify(v, ':t')
        local absolute_path = current_path .. '/' .. v

        local isdir = vim.fn.isdirectory(absolute_path)
        if isdir == 1 then
            icon, hl = mini_icons.get('directory', name)
        else
            icon, hl = mini_icons.get('file', name)
        end

        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
            sign_text = icon,
            sign_hl_group = hl,
        })
    end
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
