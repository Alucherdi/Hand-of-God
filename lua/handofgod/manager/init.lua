local commons = require('handofgod.commons')
local utils   = require('handofgod.utils')

local data = require('handofgod.data')

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
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
end

local function gen_list(path)
    local files = {}
    M.bufferPath = path or vim.fn.expand('%:p:h')

    local hidden = vim.fn.globpath(M.bufferPath, '.*', false, true)
    local normal = vim.fn.globpath(M.bufferPath, '*', false, true)
    local list = vim.list_extend(normal, hidden)

    for _, item in pairs(list) do
        local rel = vim.fn.fnamemodify(item, ':t')

        if utils.includes(M.ignore, rel) then goto skip end
        if rel == '.' or rel == '..' then goto skip end

        local stat = vim.loop.fs_stat(item)
        if not stat then goto skip end

        if stat.type == 'directory' then
            table.insert(files, 1, rel .. '/')
        else
            table.insert(files, rel)
        end

        ::skip::
    end

    return files
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

        local additions = utils.get_diff(lines, list)
        local subtraction = utils.get_diff(list, lines)
        self:manage(additions, subtraction)
        print('Saved :)')
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
        local result = vim.fn.delete(M.bufferPath .. '/' .. path)

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
