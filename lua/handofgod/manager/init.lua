local commons = require('handofgod.commons')
local utils   = require('handofgod.utils')
local save_window = require('handofgod.manager.save')
local rename_window = require('handofgod.manager.rename')
local data = require('handofgod.data')
local marker = require('handofgod.helpers.jumper_marks')

local ns = vim.api.nvim_create_namespace('HOGManagerNS')

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
            add_to_jump_list = '<leader>a'
        },

        rename = {
            keybinds = {
                save_and_exit = 'q',
                exit = '<Esc>'
            }
        },

        save_confirmation = {
            keybinds = {
                confirm = 'y',
                cancel  = 'n',
            }
        }
    },

    mod = {},
    host = nil,
    is_active = false,
    files = {},
    being_modified = false
}

function M:setup(config)
    if not config then return end
    self.config = vim.tbl_deep_extend('force', self.config, config or {})

    save_window.keybinds = self.config.save_confirmation.keybinds
    rename_window.keybinds = self.config.rename.keybinds
end

local function gen_title(path)
    local title = vim.fn.fnamemodify(path, ':.')
    if title == vim.uv.cwd() then
        title = './'
    end
    return title
end

local function gen_list(path)
    M.buffer_path = path or vim.fn.expand('%:p:h')
    return data.ls(M.buffer_path, M.config.ignore)
end

local function set_list_to_buffer(list, listbuf, current_path)
    if not vim.api.nvim_buf_is_valid(listbuf) then return end
    if not current_path then
        current_path = vim.fn.expand('%:p:h')
    end

    vim.api.nvim_buf_set_lines(listbuf, 0, -1, false, list)
    commons.set_icons(listbuf, list, ns, current_path)
    marker.set_manager_marks(listbuf, ns, utils.map(list, function(el)
        return vim.fn.fnamemodify(M.buffer_path .. '/' .. el, ':.')
    end))
end

function M:open()
    M.buffer_path = vim.fn.expand('%:p:h')

    M.host = vim.api.nvim_get_current_win()
    M.list = gen_list()

    M.mod = commons:create_window(gen_title(M.buffer_path))
    marker.remove_marks(M.mod.buf, ns)

    set_list_to_buffer(M.list, M.mod.buf, M.buffer_path)

    utils.kmap('n', M.config.keybinds.add_to_jump_list, function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local path = vim.fn.fnamemodify(M.buffer_path .. '/' .. M.list[row], ':.')
        local jumplist_index = utils.index_of(data.list, path, 'key')
        if jumplist_index ~= -1 then
            table.remove(data.list, jumplist_index)
            marker.remove_mark_at(M.mod.buf, ns, row)
            marker.set_manager_marks(M.mod.buf, ns, utils.map(M.list, function(el)
                return vim.fn.fnamemodify(M.buffer_path .. '/' .. el, ':.')
            end))
            return
        end

        data.add(path)
        marker.set_mark_at(M.mod.buf, ns, row)
    end, {buffer = M.mod.buf})

    utils.kmap('n', M.config.keybinds.push_back, function()
        M.being_modified = false
        local new_path = vim.fn.fnamemodify(M.buffer_path, ':h')
        M.list = gen_list(new_path)
        set_list_to_buffer(M.list, M.mod.buf, new_path)
        vim.api.nvim_win_set_config(M.mod.win, {title = gen_title(M.buffer_path)})
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
            self:edit(M.buffer_path .. '/' .. line)
            commons.close(M.mod)
        end
    end, {buffer = M.mod.buf})

    utils.kmap('n', M.config.keybinds.rename_file, function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(M.mod.buf, row - 1, row, false)[1]

        rename_window.spawn(line, M.buffer_path .. '/',
            function()
                set_list_to_buffer(gen_list(M.buffer_path), M.mod.buf)
            end)
    end, {buffer = M.mod.buf})

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = M.mod.buf,
        callback = function(_)
            self.is_active = false
        end
    })

    vim.api.nvim_create_autocmd('TextChanged', {
        buffer = M.mod.buf,
        callback = function(_)
            if M.being_modified then
                marker.remove_marks(M.mod.buf, ns)
            end
            M.being_modified = true
        end
    })

    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = M.mod.buf,
        callback = function(_)
            if M.being_modified then
                marker.remove_marks(M.mod.buf, ns)
            end
            M.being_modified = true
        end
    })

    vim.api.nvim_create_autocmd('BufLeave', {
        buffer = M.mod.buf,
        callback = function(_)
            M.being_modified = false
            marker.remove_marks(M.mod.buf, ns)
        end
    })
end

function M.manage(additions, subtractions)
    for _, path in ipairs(additions) do
        local dir = M.buffer_path .. '/' .. vim.fn.fnamemodify(path, ':h')
        if dir then vim.fn.mkdir(dir, 'p') end

        if path:sub(-1) ~= '/' then
            vim.fn.writefile({}, M.buffer_path .. '/' .. path)
        end
    end

    for _, path in ipairs(subtractions) do
        local file_path = M.buffer_path .. '/' .. path
        local result = vim.fn.delete(file_path, 'rf')

        if result == -1 then return end
        local relative = vim.fn.fnamemodify(file_path, ':.')

        if file_path:sub(-1) == '/' then
            for index, v in ipairs(data.list) do
                if v.key:match('^' .. relative) then
                    data.list[index] = nil
                end
            end
        else
            local index = utils.index_of(data.list, relative, 'key')
            if index ~= -1 then
                data.list[index] = nil
            end
        end
    end
end

function M:goto(path, buf, window)
    M.being_modified = false
    local new_path = M.buffer_path .. '/' .. path:sub(0, -2)
    M.list = gen_list(new_path)

    set_list_to_buffer(M.list, buf, new_path)
    vim.api.nvim_win_set_config(window, {title = gen_title(M.buffer_path)})
end

function M:edit(path)
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.fnamemodify(vim.fn.expand(path), ':.'))
end

function M:write()
    local lines = vim.api.nvim_buf_get_lines(
        vim.api.nvim_get_current_buf(), 0, -1, false)

    local current_path = M.buffer_path
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
            end,
            function()
                set_list_to_buffer(gen_list(current_path), b, current_path)
            end
        )
    else
        self.manage(additions, deletions)
        set_list_to_buffer(gen_list(current_path), b, current_path)
        print('Files modified')
    end
end

return M
