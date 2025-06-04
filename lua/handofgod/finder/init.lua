local commons = require('handofgod.commons')
local utils = require('handofgod.utils')
local mod = require('handofgod.modules')
local ft = require('handofgod.data.filetype')

local ns = vim.api.nvim_create_namespace("HOGFinderHL")

local command = 'rg --json '

local M = {
    index = 1,
    list = {
        index = 1,
        paths = {},
        positions = {},
        matches = {},
    },
    preview = {
        cached = {
            path = '',
            buf = nil
        }
    }
}

function M:setup(config)
end

function M:edit()
    local path = M.list.paths[M.index]
    local cursor = M.list.positions[M.index]
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.expand(
        vim.fn.fnamemodify(path, ':.')))

    vim.api.nvim_win_set_cursor(0, {cursor[1], cursor[2] + 1})
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
        local json = vim.json.decode(v)
        if json.type ~= 'match' and json.type ~= 'context' then
            goto skip
        end

        local data = json.data
        local match = (data.lines.text or ''):gsub('[\n\r]$', '')

        if json.type == 'match' then
            table.insert(result.paths, vim.fn.fnamemodify(data.path.text, ':.'))
            table.insert(result.matches, match)
            table.insert(result.positions, {
                data.line_number,
                data.submatches[1].start,
                data.submatches[1]['end'],
            })
        end

        ::skip::
    end

    return result
end

local function move_cursor_keymaps(list, example, buf)
    utils.kmap('i', '<C-n>', function()
        M.index = M.index + 1
        local count = #vim.api.nvim_buf_get_lines(list.buf, 0, -1, false)
        if M.index > count then
            M.index = count
            return
        end
        vim.api.nvim_win_set_cursor(list.win, {M.index, 0})

        M.draw_example(example)
    end, {buffer = buf})

    utils.kmap('i', '<C-p>', function()
        M.index = M.index - 1
        if M.index < 1 then
            M.index = 1
            return
        end
        vim.api.nvim_win_set_cursor(list.win, {M.index, 0})

        M.draw_example(example)
    end, {buffer = buf})
end

local function create_prompt(list, example)
    local main = mod.switch('finder')
    if not main then return end

    main.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'prompt', {buf = main.buf})
    vim.fn.prompt_setprompt(main.buf, '')

    main.win = commons:create_window('input', main.buf, {
        style = 'minimal',
        row = 15,
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
        M:edit()
    end, {buffer = main.buf})

    move_cursor_keymaps(list, example, main.buf)

    vim.api.nvim_create_autocmd('bufLeave', {
        buffer = main.buf,
        callback = function()
            if vim.api.nvim_win_is_valid(list.win) then
                vim.api.nvim_win_close(list.win, true)
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

            M.list = run_command(command .. '"' .. line .. '" ' .. vim.uv.cwd())

            vim.api.nvim_buf_set_lines(list.buf, 0, -1, false, M.list.paths)
            M.draw_example(example)
        end
    })

    vim.cmd('startinsert')
end

function M.draw_example(module)
    local path = M.list.paths[M.index]
    if not path then return end
    local cached = M.preview.cached

    if cached.path ~= path or not cached.buf then
        local file = vim.fn.readfile(M.list.paths[M.index])
        vim.api.nvim_buf_set_lines(module.buf, 0, -1, false, file)
        cached.path = path
        cached.buf = module.buf
    end

    local filetype = ft.detect(M.list.paths[M.index] or '')
    vim.api.nvim_set_option_value('filetype', filetype, {buf = module.buf})

    if #M.list.positions == 0 then return end
    local cursor = M.list.positions[M.index]

    local line = cursor[1] or 1
    local start = cursor[2] or 0
    local ends = cursor[3] or 1

    vim.api.nvim_win_set_cursor(module.win, {line, start})
    vim.api.nvim_win_call(module.win, function()
        vim.cmd("normal! zz")
    end)

    vim.api.nvim_buf_set_extmark(module.buf, ns, line - 1, start, {
        end_col = ends,
        end_row = line - 1,
        hl_group = "CurSearch",
    })
end

local function create_example()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local win  = commons:create_window('', buf, {
        style = 'minimal',
        row = 11,
        height = 4,
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
        height = 10,
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

