local utils = require('handofgod.utils')
local commons = require('handofgod.commons')
local ns = vim.api.nvim_create_namespace("HOGManagerHL")

local M = {}

function M.spawn(additions, deletions, confirmation_callback)
    local list = utils.merge_list(additions, deletions)
    if #list == 0 then return end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
    M.set_buf_properties(buf, #additions, #deletions)

    local win = commons:create_window('Save? y/n', buf, {
        style = 'minimal',
        width = 20, height = #list,
        row = 1, col = 1
    })

    utils.kmap('n', 'y', function()
        confirmation_callback()
        vim.api.nvim_win_close(win, true)
        print('Saved :)')
    end, {buffer = buf, nowait = true, noremap = true})

    utils.kmap('n', 'n', function()
        vim.api.nvim_win_close(win, true)
    end, {buffer = buf, nowait = true, noremap = true})
end

function M.set_buf_properties(buf, adds, subs)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].modifiable = false
    vim.bo[buf].swapfile = false

    if adds > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
            end_row = adds,
            hl_group = "DiffAdd",
        })
    end

    if subs > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, adds, 0, {
            end_row = adds + subs,
            hl_group = "DiffDelete",
        })
    end
end

return M
