local utils = require('handofgod.utils')
local data = require('handofgod.data')
local commons = require('handofgod.commons')

local M = { current = '' }

function M.setup()
    data.load()
end

function M.add()
    data.add(vim.fn.expand('%'))
end

function M.jump_to(index)
    local element = data.list[index]
    if element == nil then return end

    local path = element.key
    if path == M.current then return end

    M.current = path
    vim.cmd('edit ' .. vim.fn.expand(path))
end

function M.rewrite(lines)
    utils.remove_empties(lines)
    data.reorder_based_on(lines)
    data.write()
end

function M.explore()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(buf, 0, 1, false, data.get_files())
    local window = commons:create_window('Jumper', buf)

    utils.kmap('n', {'<Esc>', 'q'}, function()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        M.rewrite(lines)
        vim.api.nvim_win_close(window, true)
        vim.api.nvim_buf_delete(buf, { force = true })

    end, { buffer = buf })
end

return M
