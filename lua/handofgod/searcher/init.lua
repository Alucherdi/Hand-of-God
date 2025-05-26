local commons = require('handofgod.commons')
local utils = require('handofgod.utils')
local mod = require('handofgod.modules')
local command = 'fd -c never -tf'

local M = {
    index = 1,
    selected = ''
}

function M:setup(config)
    M.ignore = config.ignore or {}

    for _, v in ipairs(M.ignore) do
        command = command .. ' -E ' .. v
    end
end

function M:match_to(line)
    local list = {}
    for _, v in ipairs(self.list) do
        if v:match(line) then
            table.insert(list, v)
        end
    end

    return list
end

function M:edit(path)
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.expand(path))
end

local function run_command(cmd)
    local output = vim.fn.system(cmd)

    if vim.v.shell_error ~= 0 then
        print("Error running command: " .. cmd)
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
        M.selected = vim.api.nvim_buf_get_lines(target.buf, M.index - 1, M.index, false)[1]
    end, {buffer = buf})

    utils.kmap('i', '<C-p>', function()
        M.index = M.index - 1
        if M.index < 1 then
            M.index = 1
            return
        end
        vim.api.nvim_win_set_cursor(target.win, {M.index, 0})
        M.selected = vim.api.nvim_buf_get_lines(target.buf, M.index - 1, M.index, false)[1]
        print(M.selected)
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
        row = 13,
        col = 0,
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
        M:edit(M.selected)
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
            M.selected = vim.api.nvim_buf_get_lines(target.buf, 0, 1, false)[1]
            local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

            if vim.trim(line) == "" then
                M.list = run_command(command) or {}
                vim.api.nvim_buf_set_lines(target.buf, 0, -1, false, M.list)
                return
            end

            local result = M:match_to(line)
            vim.api.nvim_buf_set_lines(target.buf, 0, -1, false, result)
        end
    })

    vim.cmd('startinsert')
end


local function create_list()
    M.host = vim.api.nvim_get_current_win()

    M.index = 1
    M.selected = ''
    M.list = run_command(command) or {}
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.list)

    local win  = commons:create_window('Searcher', buf)

    return buf, win
end

function M:open()
    local buf, win  = create_list()
    create_prompt({win = win, buf = buf})
end

return M
