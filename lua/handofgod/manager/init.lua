local commons = require('handofgod.commons')
local utils   = require('handofgod.utils')

local M = {}

local function gen_list(path)
    local files = {}

    M.bufferPath = path or vim.fn.expand('%:p:h')

    local hidden = vim.fn.globpath(M.bufferPath, '.*', false, true)
    local normal = vim.fn.globpath(M.bufferPath, '*', false, true)
    local list = vim.list_extend(normal, hidden)


    for _, item in pairs(list) do
        local stat = vim.loop.fs_stat(item)
        local rel = vim.fn.fnamemodify(item, ':t')
        if rel == '.' or rel == '..' then goto skip end

        if stat then
            if stat.type == 'directory' then
                table.insert(files, 1, rel .. '/')
            else
                table.insert(files, rel)
            end
        end
        ::skip::
    end

    return files
end

function M:open()
    M.host = vim.api.nvim_get_current_win()

    local list = gen_list()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)

    local title = vim.fn.fnamemodify(M.bufferPath, ':.')

    if title == vim.uv.cwd() then
        title = './'
    end

    local window = commons:create_window(
        title,
        buf)

    vim.keymap.set('n', '<BS>', function()
        list = gen_list(vim.fn.fnamemodify(M.bufferPath, ':h'))
        local title = vim.fn.fnamemodify(M.bufferPath, ':.')
        if title == vim.uv.cwd() then
            title = './'
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
        vim.api.nvim_win_set_config(window, {title = title})
    end)

    vim.keymap.set('n', '<leader>u', function()
        local lines = vim.api.nvim_buf_get_lines(
            vim.api.nvim_get_current_buf(), 0, -1, false)

        local additions = utils.get_diff(lines, list)
        local subtraction = utils.get_diff(list, lines)
        self:manage(additions, subtraction)

    end, { buffer = buf })

    for _, k in ipairs({'<Esc>', 'q'}) do
        vim.keymap.set('n', k, function()
            vim.api.nvim_win_close(window, true)
            vim.api.nvim_buf_delete(buf, { force = true })
        end, { buffer = buf })
    end

    vim.keymap.set('n', '<CR>', function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

        if line:sub(-1) == '/' then
            self:goto(line, buf, window)
        else
            self:edit(M.bufferPath .. '/' .. line)
            vim.api.nvim_win_close(window, true)
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end, { buffer = buf })
end

function M:manage(additions, subtractions)
    for _, path in ipairs(additions) do
        local dir = M.bufferPath .. '/' .. vim.fn.fnamemodify(path, ':h')
        if dir then vim.fn.mkdir(dir, 'p') end

        vim.fn.writefile({}, M.bufferPath .. '/' .. path)
    end

    for _, path in ipairs(subtractions) do
        vim.fn.delete(M.bufferPath .. '/' .. path)
    end
end

function M:goto(path, buf, window)
    local list = gen_list(M.bufferPath .. '/' .. path:sub(0, -2))
    local title = vim.fn.fnamemodify(M.bufferPath, ':.')
    if title == vim.uv.cwd() then
        title = './'
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
    vim.api.nvim_win_set_config(window, {title = title})
end

function M:edit(path)
    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.fnamemodify(vim.fn.expand(path), ':.'))
end

return M
