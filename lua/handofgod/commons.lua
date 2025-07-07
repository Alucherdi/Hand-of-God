local M = {
    separator = '[HOG_SEP]'
}
local function win_size()
    return vim.o.columns, vim.o.lines - vim.o.cmdheight - (vim.o.laststatus > 0 and 1 or 0)
end

local min = {
    w = 64,
    h = 20,
}

local function get_offset()
    local cw, ch = win_size()

    local x = 16
    local y = 4

    if cw <= min.w then x = 0 end
    if ch <= min.h then y = 0 end

    return x, y
end

function M.create_prompted_window(prompt_title, main_title)
    local x, py = get_offset()
    local w, h = win_size()
    local y = py + 2
    local ph = 1
    h = h - (y * 2)
    h = (h < 0 and 1 or h)
    w = w - (x * 2)

    local prompt = {
        buf = nil,
        win = nil,
        conf = {
            relative = 'editor',
            title = prompt_title,
            border = 'single',
            title_pos = 'center',
            style = 'minimal',
            height = ph,
            width = w,
            row = py,
            col = x
        }
    }

    local main = {
        buf = nil,
        win = nil,
        conf = {
            relative = 'editor',
            title = main_title,
            border = 'single',
            title_pos = 'center',
            style = 'minimal',
            height = h,
            width = w,
            row = y,
            col = x
        }
    }

    prompt.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'prompt', {buf = prompt.buf})
    vim.fn.prompt_setprompt(prompt.buf, '')
    prompt.win = vim.api.nvim_open_win(prompt.buf, true, prompt.conf)

    main.buf = vim.api.nvim_create_buf(false, true)
    main.win = vim.api.nvim_open_win(main.buf, true, main.conf)
    vim.cmd('set cursorline')

    return prompt, main
end

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
