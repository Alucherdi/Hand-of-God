local utils = require('handofgod.utils')
local data = require('handofgod.data')

local M = { current = '' }

function M.setup()
    print('being setup')
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
    local window = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        height = 12, width = 64,
        row = 0, col = 0
    })

    vim.keymap.set('n', 'q', function()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        --[[
        local diff = utils.get_diff(M.list, lines)

        if #diff > 0 then
            events.clean_cursors(diff)
            events.save_cursors()
        end
        ]]--

        M.rewrite(lines)
        vim.api.nvim_win_close(window, true)
        vim.api.nvim_buf_delete(buf, { force = true })

    end, { buffer = buf })
end

return M
