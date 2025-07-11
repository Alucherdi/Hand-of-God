local commons = require('handofgod.commons')
local utils = require('handofgod.utils')
local command = 'fd -c never -tf -I'
local data = require('handofgod.data')
local ns = vim.api.nvim_create_namespace('HOGSearcherNS')
local jumper_marks = {}

local M = {
    index = 1,
    selected = '',
    original = nil,
    config = {} --[[{
        contract_on_large_paths = false,
        ignore = {},
        caseSensitive = false,
    }]]--,
}

local function remove_jumper_mark_at(buf, index)
    vim.api.nvim_buf_del_extmark(buf, ns, jumper_marks[index])
    jumper_marks[index] = nil
end

local function set_jumper_mark_at(buf, index)
    local i = vim.api.nvim_buf_set_extmark(buf, ns, index - 1, index, {
        virt_text = {{'(J)', 'Special'}},
        virt_text_pos = 'eol',
    })

    jumper_marks[index] =  i
end

local function set_jumper_mark(buf, list)
    for i, v in ipairs(list) do
        local index = utils.index_of(data.list, v, 'key')
        if index ~= -1 then
            set_jumper_mark_at(buf, i)
        end
    end
end


function M:setup(config)
    M.config.case_sensitive = config.case_sensitive or false
    M.config.contract_on_large_paths = config.contract_on_large_paths or false

    for _, v in ipairs(config.ignore) do
        command = command .. ' -E ' .. v
    end
end


function M:open()
    M.host = vim.api.nvim_get_current_win()
    M.original = M.get_files()
    M.list = M.original

    local prompt, main = commons.create_prompted_window('fd', '')
    M.manage_main(main)
    M.manage_prompt(main, prompt)

    vim.api.nvim_set_current_win(prompt.win)
    vim.cmd('startinsert')
end

function M:match_to(line)
    local list = {}
    for _, v in ipairs(self.original) do
        if v:lower():match(line:lower()) then
            table.insert(list, v)
        end
    end

    return list
end

function M:edit(path)
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.expand(vim.fn.fnamemodify(path, ':.')))
end

function M.get_files()
    local output = vim.fn.system(command)

    if vim.v.shell_error ~= 0 then
        print("Error running command: " .. command)
        return nil
    end

    return vim.split(output, '\n', {trimempty=true})
end

local function move_cursor_keymaps(target, buf)
    utils.kmap('i', '<C-n>', function()
        M.index = M.index + 1
        local count = #vim.api.nvim_buf_get_lines(target.buf, 0, -1, false)
        if M.index > count then
            M.index = count
            return
        end
        vim.api.nvim_win_set_cursor(target.win, {M.index, 0})
    end, {buffer = buf})

    utils.kmap('i', '<C-p>', function()
        M.index = M.index - 1
        if M.index < 1 then
            M.index = 1
            return
        end
        vim.api.nvim_win_set_cursor(target.win, {M.index, 0})
    end, {buffer = buf})
end

function M.manage_prompt(main, prompt)
    utils.kmap('n', {'q', '<Esc>'}, function()
        commons.close(prompt)
    end, {buffer = prompt.buf})

    utils.kmap('i', '<Esc>', function()
        commons.close(prompt)
        vim.api.nvim_set_current_win(M.host)
    end, {buffer = prompt.buf})

    utils.kmap('i', '<CR>', function()
        commons.close(prompt)
        M:edit(M.list[M.index])
    end, {buffer = prompt.buf})

    utils.kmap('i', '<C-a>', function()
        local index = utils.index_of(data.list, M.list[M.index], 'key')
        print(index)
        if index ~= -1 then
            table.remove(data.list, index)
            remove_jumper_mark_at(main.buf, M.index)
            return
        end

        data.add(M.list[M.index])
        set_jumper_mark_at(main.buf, M.index)
    end, {buffer = prompt.buf})

    move_cursor_keymaps(main, prompt.buf)

    vim.api.nvim_create_autocmd('bufLeave', {
        buffer = prompt.buf,
        callback = function()
            if vim.api.nvim_win_is_valid(main.win) then
                vim.api.nvim_win_close(main.win, true)
            end
        end
    })

    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = prompt.buf,
        callback = function(_)
            M.index = 1

            local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

            if vim.trim(line) == "" then
                M.list = M.original
            else
                M.list = M:match_to(line)
            end

            local list = M.list
            list = M.handle_contraction(list)

            vim.api.nvim_buf_set_lines(main.buf, 0, -1, false, list)
            commons.set_icons(main.buf, M.list, ns, vim.uv.cwd())
            set_jumper_mark(main.buf, list)
        end
    })

end

function M.manage_main(main)
    M.index = 1
    local list = M.list
    list = M.handle_contraction(list)

    vim.api.nvim_buf_set_lines(main.buf, 0, -1, false, list)
    commons.set_icons(main.buf, list, ns, vim.uv.cwd())
    set_jumper_mark(main.buf, list)
end


function M.handle_contraction(list)
    if M.config.contract_on_large_paths then
        list = utils.map(list, function(v)
            if #v < 64 then return v end

            local reduced = {}
            local names = vim.split(v, '/', {trimempty = true})
            for i = 1, #names - 1 do
                reduced[i] = names[i]:sub(1, 1)
            end
            table.insert(reduced, names[#names])
            return table.concat(reduced, '/')
        end)
    end

    return list
end

return M
