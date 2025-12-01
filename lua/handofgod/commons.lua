local M = {
    separator = '[HOG_SEP]'
}
function M.win_size()
    return vim.o.columns, vim.o.lines - vim.o.cmdheight - (vim.o.laststatus > 0 and 1 or 0)
end

local min = {
    w = 64,
    h = 20,
}

local function get_offset()
    local cw, ch = M.win_size()

    local x = math.floor((cw * 0.2) + 0.5)
    local y = math.floor((ch * 0.1) + 0.5)

    if cw <= min.w then x = 0 end
    if ch <= min.h then y = 0 end

    return x, y
end

function M.create_prompted_window(prompt_title, main_title)
    _G.hog_module_loaded = true

    local x, py = get_offset()
    local w, h = M.win_size()
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

function M:create_window(title)
    _G.hog_module_loaded = true
    local x, y = get_offset()
    local w, h = M.win_size()
    w = w - (x * 2)
    h = h - (y * 2)

    local main = {
        win = nil,
        buf = nil,
        conf = {
            relative = 'editor',
            style = 'minimal',
            title = title,
            border = 'single',
            title_pos = 'center',
            height = h, width = w, row = y, col = x
        }
    }

    main.buf = vim.api.nvim_create_buf(false, true)
    main.win = vim.api.nvim_open_win(main.buf, true, main.conf)

    return main
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

    if #paths == 0 then
        local extmarks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
        for _, v in ipairs(extmarks) do
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

    _G.hog_module_loaded = false
    mod.win = nil
    mod.buf = nil
    mod.is_active = false
end

return M
