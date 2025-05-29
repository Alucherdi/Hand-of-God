local commons = require('handofgod.commons')
local utils = require('handofgod.utils')
local mod = require('handofgod.modules')

local command = 'rg --vimgrep '

local M = {
    index = 1,
    list = {
        index = 1,
        paths = {},
        positions = {},
        matches = {},
    }
}

function M:setup(config)
end

function M:edit(path)
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.expand(path))
end

local function run_command(cmd)
    local output = vim.fn.system(cmd)
    local result = {
        paths = {},
        positions = {},
        matches = {},
    }

    if vim.v.shell_error ~= 0 then return result end

    local splitted = vim.split(output, '\n', {trimempty=true})

    for _, v in ipairs(splitted) do
        local el = vim.split(v, ':', {trimempty=true})
        table.insert(result.paths, vim.fn.fnamemodify(el[1], ':.'))
        table.insert(result.positions, {el[2], el[3]})
        table.insert(result.matches, vim.trim(el[4]))
    end
    print(vim.inspect(result))

    return result
end

local function move_cursor_keymaps(target, example, buf)
    utils.kmap('i', '<C-n>', function()
        M.index = M.index + 1
        local count = #vim.api.nvim_buf_get_lines(target.buf, 0, -1, false)
        if M.index > count then
            M.index = count
            return
        end
        vim.api.nvim_win_set_cursor(target.win, {M.index, 0})

        vim.api.nvim_buf_set_lines(example.buf, 0, -1, false, {M.list.matches[M.index]})
        vim.api.nvim_win_set_cursor(example.win, {1, 0})
    end, {buffer = buf})

    utils.kmap('i', '<C-p>', function()
        M.index = M.index - 1
        if M.index < 1 then
            M.index = 1
            return
        end
        vim.api.nvim_win_set_cursor(target.win, {M.index, 0})

        vim.api.nvim_buf_set_lines(example.buf, 0, -1, false, {M.list.matches[M.index]})
        vim.api.nvim_win_set_cursor(example.win, {1, 0})
    end, {buffer = buf})
end

local function create_prompt(target, example)
    local main = mod.switch('finder')
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

    --[[
    utils.kmap('i', '<CR>', function()
        commons.close(main)
        M:edit(M.selected)
    end, {buffer = main.buf})
    ]]--

    move_cursor_keymaps(target, example, main.buf)

    vim.api.nvim_create_autocmd('bufLeave', {
        buffer = main.buf,
        callback = function()
            if vim.api.nvim_win_is_valid(target.win) then
                vim.api.nvim_win_close(target.win, true)
            end

            if vim.api.nvim_win_is_valid(example.win) then
                vim.api.nvim_win_close(example.win, true)
            end
        end
    })

    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = main.buf,
        callback = function(_)
            M.index = 1

            local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

            if vim.trim(line) == '' then return end

            local result = run_command(command .. '"' .. line .. '" ' .. vim.uv.cwd())
            vim.api.nvim_buf_set_lines(target.buf, 0, -1, false, result.paths)
            vim.api.nvim_buf_set_lines(example.buf, 0, -1, false, {result.matches[M.index]})
        end
    })

    vim.cmd('startinsert')
end

local function create_example()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local win  = commons:create_window('', buf, {
        style = 'minimal',
        width = 20,
        col = 64,
    })
    vim.cmd('set cursorline')

    return {win = win, buf = buf}
end

local function create_list()
    M.host = vim.api.nvim_get_current_win()

    M.index = 1
    M.selected = ''
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local win  = commons:create_window('Finder', buf, {
        style = 'minimal',
    })
    vim.cmd('set cursorline')

    return {win = win, buf = buf}
end

function M:open()
    local list = create_list()
    local example = create_example()
    create_prompt(list, example)
end

return M

