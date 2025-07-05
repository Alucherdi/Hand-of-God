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

    mod = {},
    host = nil,
    is_active = false,
    files = {}
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
    if not vim.api.nvim_buf_is_valid(listbuf) then return end
    if not current_path then
        current_path = vim.fn.expand('%:p:h')
    end

    vim.api.nvim_buf_set_lines(listbuf, 0, -1, false, list)
    commons.set_icons(listbuf, list, ns, current_path)
end

function M:setup(config)
    if not config then return end
    self.config = vim.tbl_deep_extend('force', self.config, config)

end

function M:open()
    M.host = vim.api.nvim_get_current_win()
    M.list = gen_list()

    M.mod.buf = vim.api.nvim_create_buf(false, true)
    set_list_to_buffer(M.list, M.mod.buf)

    M.mod.win = commons:create_window(
        gen_title(M.bufferPath),
        M.mod.buf, {
            style = 'minimal'
        })

    utils.kmap('n', M.config.keybinds.push_back, function()
        local new_path = vim.fn.fnamemodify(M.bufferPath, ':h')
        M.list = gen_list(new_path)
        set_list_to_buffer(M.list, M.mod.buf, new_path)
        vim.api.nvim_win_set_config(M.mod.win, {title = gen_title(M.bufferPath)})
    end, {buffer = M.mod.buf})

    utils.kmap('n', M.config.keybinds.close, function()
        if self.config.write_on_exit then
            self:write()
        end

        commons.close(M.mod)
    end, {buffer = M.mod.buf})

    utils.kmap('n', M.config.keybinds.write_prompt, function()
        self:write()
    end, {buffer = M.mod.buf})

    utils.kmap('n', M.config.keybinds.go_to, function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(M.mod.buf, row - 1, row, false)[1]

        if line:sub(-1) == '/' then
            self:goto(line, M.mod.buf, M.mod.win)
        else
            self:edit(M.bufferPath .. '/' .. line)
            commons.close(M.mod)
        end
    end, {buffer = M.mod.buf})

    utils.kmap('n', M.config.keybinds.rename_file, function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(M.mod.buf, row - 1, row, false)[1]

        rename_window.spawn(line, M.bufferPath .. '/',
            function()
                set_list_to_buffer(gen_list(M.bufferPath), M.mod.buf)
            end)
    end, {buffer = M.mod.buf})

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = M.mod.buf,
        callback = function(_)
            self.is_active = false
        end
    })
end

function M.manage(additions, subtractions)
    for _, path in ipairs(additions) do
        local dir = M.bufferPath .. '/' .. vim.fn.fnamemodify(path, ':h')
        if dir then vim.fn.mkdir(dir, 'p') end

        if path:sub(-1) ~= '/' then
            vim.fn.writefile({}, M.bufferPath .. '/' .. path)
        end
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
    local list = gen_list(new_path)

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

    local current_path = M.bufferPath
    local actual = gen_list(current_path)
    local additions = utils.get_diff(lines, actual)
    local deletions = utils.get_diff(actual, lines)

    local b = vim.api.nvim_get_current_buf()
    if self.config.ask_confirmation then
        save_window.spawn(additions, deletions,
            function()
                self.manage(additions, deletions)
                set_list_to_buffer(gen_list(current_path), b, current_path)
                print('Files modified')
            end)
    else
        self.manage(additions, deletions)
        set_list_to_buffer(gen_list(current_path), b, current_path)
        print('Files modified')
    end
end

return M
