local commons = require('handofgod.commons')
local command = 'fd -c never -tf'
local M = {
    index = 1,
    selected = ''
}

local function close(win, buf)
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
end

--- Set configuration parameters to searcher module
-- @param config table: The search query
-- field config.ignore table: List of path names to ignore
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
    vim.keymap.set('i', '<C-n>', function()
        M.index = M.index + 1
        local count = #vim.api.nvim_buf_get_lines(target.buf, 0, -1, false)
        if M.index > count then
            M.index = count
            return
        end
        vim.api.nvim_win_set_cursor(target.win, {M.index, 0})
        M.selected = vim.api.nvim_buf_get_lines(target.buf, M.index - 1, M.index, false)[1]
    end, {buffer = buf})

    vim.keymap.set('i', '<C-p>', function()
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
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'prompt', {buf = buf})
    vim.fn.prompt_setprompt(buf, '')

    local win = commons:create_window('input', buf, {
        style = 'minimal',
        row = 13,
        col = 0,
        height = 1
    })

    vim.keymap.set('n', 'q', function()
        close(win, buf)
    end, {buffer = buf})


    vim.keymap.set('i', '<Esc>', function()
        close(win, buf)
    end, {buffer = buf})

    vim.keymap.set('n', '<Esc>', function()
        close(win, buf)
    end, {buffer = buf})

    vim.keymap.set('i', '<CR>', function()
        close(win, buf)
        M:edit(M.selected)
    end, {buffer = buf})

    move_cursor_keymaps(target, buf)

    vim.api.nvim_create_autocmd('BufLeave', {
        buffer = buf,
        callback = function()
            if vim.api.nvim_win_is_valid(target.win) then
                vim.api.nvim_win_close(target.win, true)
            end
        end
    })

    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = buf,
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

    return buf, win
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
