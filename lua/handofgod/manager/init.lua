local commons = require('handofgod.commons')
local utils   = require('handofgod.utils')

local save_window = require('handofgod.manager.save_window')
local rename_window = require('handofgod.manager.rename_window')

local data = require('handofgod.data')
local mod = require('handofgod.modules')

local M = {
    config = {
        ignore = {},
        write_on_exit = true
    },

    is_active = false,
}

local function gen_title(path)
    local title = vim.fn.fnamemodify(path, ':.')
    if title == vim.uv.cwd() then
        title = './'
    end
    return title
end

local function gen_list(path)
    M.bufferPath = path or vim.fn.expand('%:p:h')
    return data.ls(M.bufferPath, M.config.ignore)
end

function M:setup(config)
    self.config = vim.tbl_extend('force', self.config, config or {})
end

function M:open()
    local main = mod.switch('manager')
    if not main then return end

    M.host = vim.api.nvim_get_current_win()
    local list = gen_list()

    main.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(main.buf, 0, -1, false, list)

    main.win = commons:create_window(
        gen_title(M.bufferPath),
        main.buf)

    utils.kmap('n', '<BS>', function()
        list = gen_list(vim.fn.fnamemodify(M.bufferPath, ':h'))
        vim.api.nvim_buf_set_lines(main.buf, 0, -1, false, list)
        vim.api.nvim_win_set_config(main.win, {title = gen_title(M.bufferPath)})
    end)

    utils.kmap('n', {'<Esc>', 'q'}, function()
        if self.config.write_on_exit then
            self:write()
        end

        commons.close(main)
    end, {buffer = main.buf})

    utils.kmap('n', '<leader>w', function()
        self:write()
    end, {buffer = main.buf})

    utils.kmap('n', '<CR>', function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(main.buf, row - 1, row, false)[1]

        if line:sub(-1) == '/' then
            self:goto(line, main.buf, main.win)
        else
            self:edit(M.bufferPath .. '/' .. line)
            commons.close(main)
        end
    end, {buffer = main.buf})

    utils.kmap('n', '<leader>rn', function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(main.buf, row - 1, row, false)[1]

        rename_window.spawn(line, M.bufferPath .. '/',
            function() vim.api.nvim_buf_set_lines(main.buf, 0, -1, false, gen_list(M.bufferPath)) end)
    end, {buffer = main.buf})

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = main.buf,
        callback = function(_)
            self.is_active = false
        end
    })
end

function M.manage(additions, subtractions)
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

function M:write()
    local lines = vim.api.nvim_buf_get_lines(
        vim.api.nvim_get_current_buf(), 0, -1, false)

    local actual = gen_list(self.bufferPath)
    local additions = utils.get_diff(lines, actual)
    local deletions = utils.get_diff(actual, lines)

    save_window.spawn(additions, deletions,
        function() self.manage(additions, deletions) end)
end


return M
