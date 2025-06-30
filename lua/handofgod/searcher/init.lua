local commons = require('handofgod.commons')
local utils = require('handofgod.utils')
local mod = require('handofgod.modules')
local command = 'fd -c never -tf -I'

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


function M:setup(config)
    M.config.case_sensitive = config.case_sensitive or false
    M.config.contract_on_large_paths = config.contract_on_large_paths or false

    for _, v in ipairs(config.ignore) do
        command = command .. ' -E ' .. v
    end
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

local function get_files()
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

local function create_prompt(target)
    local main = mod.switch('searcher')
    if not main then return end

    main.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'prompt', {buf = main.buf})
    vim.fn.prompt_setprompt(main.buf, '')

    main.win = commons:create_window('input', main.buf, {
        style = 'minimal',
        row = target.offset.y - 2,
        col = target.offset.x,
        height = 1
    })

    utils.kmap('n', {'q', '<Esc>'}, function()
        commons.close(main)
    end, {buffer = main.buf})

    utils.kmap('i', '<Esc>', function()
        commons.close(main)
    end, {buffer = main.buf})

    utils.kmap('i', '<CR>', function()
        commons.close(main)
        M:edit(M.list[M.index])
    end, {buffer = main.buf})

    move_cursor_keymaps(target, main.buf)

    vim.api.nvim_create_autocmd('bufLeave', {
        buffer = main.buf,
        callback = function()
            if vim.api.nvim_win_is_valid(target.win) then
                vim.api.nvim_win_close(target.win, true)
            end
        end
    })

    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = main.buf,
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

            vim.api.nvim_buf_set_lines(target.buf, 0, -1, false, list)
        end
    })

    vim.cmd('startinsert')
end

local function create_list()
    M.host = vim.api.nvim_get_current_win()

    M.index = 1
    local list = M.list
    list = M.handle_contraction(list)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)

    local win, offset, size = commons:create_window('Searcher', buf, {
        style = 'minimal',
    })
    vim.cmd('set cursorline')

    return {buf = buf, win = win, offset = offset, size = size}
end

function M:open()
    M.original = get_files()
    M.list = M.original

    local list_module = create_list()
    create_prompt(list_module)
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
