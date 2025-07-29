local utils = require('handofgod.utils')

local jumplist = require('handofgod.data.jumplist')

local commons = require('handofgod.commons')
local ns = vim.api.nvim_create_namespace('HOGJumperNS')

local M = {
    host = nil
}

function M.setup()
    jumplist.ensure_dir()
    jumplist.load()
end

function M.add()
    local path = vim.fn.expand('%:.')
    if not path then return end

    jumplist.add(path)
end

function M.jump_to(index)
    local element = jumplist.list[index]
    if element == nil then return end

    local path = element.key
    if path == vim.fn.expand('%') then return end

    vim.cmd('edit ' .. vim.fn.expand(path))
    vim.api.nvim_win_set_cursor(0, element.cursor)
end

function M.rewrite(lines)
    utils.remove_empties(lines)
    jumplist.reorder_based_on(lines)
    jumplist.write()
end

function M.explore()
    M.host = vim.api.nvim_get_current_win()
    local main = commons:create_window('Jumper')

    local files = utils.map(jumplist.get_list(), function(v) return v.key end)

    vim.api.nvim_buf_set_lines(main.buf, 0, 1, false, files)
    commons.set_icons(main.buf, files, ns, vim.uv.cwd())

    utils.kmap('n', {'<Esc>', 'q'}, function()
        local lines = vim.api.nvim_buf_get_lines(main.buf, 0, -1, false)

        M.rewrite(lines)
        commons.close(main)
    end, { buffer = main.buf })

    utils.kmap('n','<CR>', function ()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(main.buf, row - 1, row, false)[1]

        vim.api.nvim_set_current_win(M.host)
        vim.cmd("edit " .. line)
        commons.close(main)

    end, { buffer = main.buf })
end

return M
