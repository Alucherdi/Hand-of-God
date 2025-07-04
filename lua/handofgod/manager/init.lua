local commons = require('handofgod.commons')
local utils   = require('handofgod.utils')

local save_window = require('handofgod.manager.save_window')
local rename_window = require('handofgod.manager.rename_window')

local ns = vim.api.nvim_create_namespace('HOGManagerNS')
local data = require('handofgod.data')

local M = {
    config = {
        ignore = {},
        write_on_exit = true,
        ask_confirmation = true,

        keybinds = {
            rename_file = '<leader>rn',
            write_prompt = '<leader>w',
            push_back = '<BS>',
            close = {'<Esc>', 'q'},
            go_to = '<CR>',
        },
    },

    is_active = false,
}

local function gen_title(path)
    local title = vim.fn.fnamemodify(path, ':.')
    if title == vim.uv.cwd() then
        title = './'
    end
    return title
end

local function gen_list(path)
    M.bufferPath = path or vim.fn.expand('%:p:h')
    return data.ls(M.bufferPath, M.config.ignore)
end

local function set_list_to_buffer(list, listbuf, current_path)
    if not current_path then
        current_path = vim.fn.expand('%:p:h')
    end

    vim.api.nvim_buf_set_lines(listbuf, 0, -1, false, list)

    local mini_icons = _G.MiniIcons

    if not mini_icons then return end

    for i, v in ipairs(list) do
        local icon, hl
        local name = vim.fn.fnamemodify(v, ':t')
        local absolute_path = current_path .. '/' .. v

        local isdir = vim.fn.isdirectory(absolute_path)
        if isdir == 1 then
            icon, hl = mini_icons.get('directory', name)
        else
            icon, hl = mini_icons.get('file', name)
        end

        vim.api.nvim_buf_set_extmark(listbuf, ns, i - 1, 0, {
            sign_text = icon,
            sign_hl_group = hl,
        })
    end

end

function M:setup(config)
    if not config then return end
    self.config = vim.tbl_deep_extend('force', self.config, config)

end

function M:open()
    local main = {}
    if not main then return end

    M.host = vim.api.nvim_get_current_win()
    local list = gen_list()

    main.buf = vim.api.nvim_create_buf(false, true)
    set_list_to_buffer(list, main.buf)

    main.win = commons:create_window(
        gen_title(M.bufferPath),
        main.buf, {
            style = 'minimal'
        })

    utils.kmap('n', M.config.keybinds.push_back, function()
        local new_path = vim.fn.fnamemodify(M.bufferPath, ':h')
        list = gen_list(new_path)
        set_list_to_buffer(list, main.buf, new_path)
        vim.api.nvim_win_set_config(main.win, {title = gen_title(M.bufferPath)})
    end, {buffer = main.buf})

    utils.kmap('n', M.config.keybinds.close, function()
        if self.config.write_on_exit then
            self:write()
        end

        commons.close(main)
    end, {buffer = main.buf})

    utils.kmap('n', M.config.keybinds.write_prompt, function()
        self:write()
    end, {buffer = main.buf})

    utils.kmap('n', M.config.keybinds.go_to, function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(main.buf, row - 1, row, false)[1]

        if line:sub(-1) == '/' then
            self:goto(line, main.buf, main.win)
        else
            self:edit(M.bufferPath .. '/' .. line)
            commons.close(main)
        end
    end, {buffer = main.buf})

    utils.kmap('n', M.config.keybinds.rename_file, function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(main.buf, row - 1, row, false)[1]

        rename_window.spawn(line, M.bufferPath .. '/',
            function()
                set_list_to_buffer(gen_list(M.bufferPath), main.buf)
            end)
    end, {buffer = main.buf})

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = main.buf,
        callback = function(_)
            self.is_active = false
        end
    })
end

function M.manage(additions, subtractions)
    for _, path in ipairs(additions) do
        local dir = M.bufferPath .. '/' .. vim.fn.fnamemodify(path, ':h')
        if dir then vim.fn.mkdir(dir, 'p') end

        vim.fn.writefile({}, M.bufferPath .. '/' .. path)
    end

    for _, path in ipairs(subtractions) do
        local result = vim.fn.delete(M.bufferPath .. '/' .. path, 'rf')

        if result == 0 then
            local relative = vim.fn.fnamemodify(M.bufferPath, ':.') .. '/' .. path
            local index = utils.index_of(data.list, relative, 'key')
            if index ~= -1 then
                data.list[index] = nil
            end
        end
    end
end

function M:goto(path, buf, window)
    local new_path = M.bufferPath .. '/' .. path:sub(0, -2)
    local list = gen_list(M.bufferPath .. '/' .. path:sub(0, -2))

    set_list_to_buffer(list, buf, new_path)
    vim.api.nvim_win_set_config(window, {title = gen_title(M.bufferPath)})
end

function M:edit(path)
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.fnamemodify(vim.fn.expand(path), ':.'))
end

function M:write()
    local lines = vim.api.nvim_buf_get_lines(
        vim.api.nvim_get_current_buf(), 0, -1, false)

    local actual = gen_list(self.bufferPath)
    local additions = utils.get_diff(lines, actual)
    local deletions = utils.get_diff(actual, lines)

    if self.config.ask_confirmation then
        save_window.spawn(additions, deletions,
            function() self.manage(additions, deletions) end)
    else
        self.manage(additions, deletions)
    end
end


return M
