require('handofgod.jumper.events')
local data = require('handofgod.jumper.data')
local M = {
    list = {},
    current = ''
}

function M.load()
    M.list = data.read()
end

function M.add()
    table.insert(M.list, vim.fn.expand('%'))
end

function M.jump_to(index)
    local path = M.list[index]
    if path == nil or path == '' or path == M.current then return end
    M.current = path
    vim.cmd('edit ' .. vim.fn.expand(M.list[index]))
end

function M.rewrite(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    M.list = lines
    data.write(lines)
end

function M.explore()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(buf, 0, 1, false, M.list)
    local window = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        height = 12, width = 64,
        row = 0, col = 0
    })

    vim.keymap.set('n', 'q', function()
        M.rewrite(buf)
        vim.api.nvim_win_close(window, true)
        vim.api.nvim_buf_delete(buf, { force = true })
    end, { buffer = buf })
end

M.load()
return M
