local commons = require('handofgod.commons')
local utils   = require('handofgod.utils')

local data = require('handofgod.data')

local ns = vim.api.nvim_create_namespace("HOGManagerHL")

local M = {
    ignore = {}
}

local function gen_title(path)
    local title = vim.fn.fnamemodify(path, ':.')
    if title == vim.uv.cwd() then
        title = './'
    end
    return title
end

local function close(win, buf)
    if win then vim.api.nvim_win_close(win, true) end

    if buf then vim.api.nvim_buf_delete(buf, { force = true }) end
end

local function gen_list(path)
    M.bufferPath = path or vim.fn.expand('%:p:h')
    return data.ls(M.bufferPath, M.ignore)
end

--- Filters a list of strings based on input
-- @param config table: The search query
-- field config.ignore table: List of path names to ignore
function M:setup(config)
    vim.tbl_extend('force', config)
end

function M:open()
    M.host = vim.api.nvim_get_current_win()

    local list = gen_list()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)

    local window = commons:create_window(
        gen_title(M.bufferPath),
        buf)

    utils.kmap('n', '<BS>', function()
        list = gen_list(vim.fn.fnamemodify(M.bufferPath, ':h'))
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
        vim.api.nvim_win_set_config(window, {title = gen_title(M.bufferPath)})
    end)

    utils.kmap('n', {'<Esc>', 'q'}, function()
        close(window, buf)
    end, { buffer = buf })

    utils.kmap('n', '<leader>w', function()
        local lines = vim.api.nvim_buf_get_lines(
            vim.api.nvim_get_current_buf(), 0, -1, false)
        local actual = gen_list(M.bufferPath)

        local additions = utils.get_diff(lines, actual)
        local subtraction = utils.get_diff(actual, lines)

        local savetext = utils.list_merge(additions, subtraction)
        local savebuf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(savebuf, 0, -1, false, savetext)

        vim.bo[savebuf].buftype = 'nofile'
        vim.bo[savebuf].bufhidden = 'wipe'
        vim.bo[savebuf].modifiable = false
        vim.bo[savebuf].swapfile = false

        if #additions > 0 then
            vim.api.nvim_buf_set_extmark(savebuf, ns, 0, 0, {
                end_row = #additions,
                hl_group = "DiffAdd",
            })
        end

        if #subtraction > 0 then
            vim.api.nvim_buf_set_extmark(savebuf, ns, #additions, 0, {
                end_row = #additions + #subtraction,
                hl_group = "DiffDelete",
            })
        end

        local savewin = commons:create_window('Save? y/n', savebuf, {
            style = 'minimal',
            width = 20, height = #savetext,
            row = 1, col = 1
        })

        utils.kmap('n', 'h', function()
            print(#subtraction)
        end, {buffer = savebuf})

        utils.kmap('n', 'y', function()
            self:manage(additions, subtraction)
            close(savewin, nil)
            print('Saved :)')
        end, {buffer = savebuf, nowait = true, noremap = true})

        utils.kmap('n', 'n', function()
            close(savewin, nil)
        end, {buffer = savebuf, nowait = true, noremap = true})

    end, { buffer = buf })

    utils.kmap('n', '<CR>', function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

        if line:sub(-1) == '/' then
            self:goto(line, buf, window)
        else
            self:edit(M.bufferPath .. '/' .. line)
            close(window, buf)
        end
    end, { buffer = buf })

    utils.kmap('n', '<leader>rn', function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

        local rnbuf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(rnbuf, 0, -1, false, {line})

        local rnwin = commons:create_window('Rename', rnbuf, {
            style = 'minimal',
            width = #line + 8, height = 1,
            row = 1, col = 1
        })

        utils.kmap('n', 'q', function()
            local rnline = vim.api.nvim_buf_get_lines(rnbuf, 0, 1, false)[1]
            print(M.bufferPath .. '/' .. rnline)

            vim.fn.rename(
                M.bufferPath .. '/' .. line,
                M.bufferPath .. '/' .. rnline
            )

            vim.api.nvim_buf_set_lines(buf, 0, -1, false, gen_list(M.bufferPath))
            close(rnwin, rnbuf)
        end, {buffer=rnbuf})

    end, {buffer = buf})
end

function M:manage(additions, subtractions)
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
    local list = gen_list(M.bufferPath .. '/' .. path:sub(0, -2))

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
    vim.api.nvim_win_set_config(window, {title = gen_title(M.bufferPath)})
end

function M:edit(path)
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.fnamemodify(vim.fn.expand(path), ':.'))
end

return M
