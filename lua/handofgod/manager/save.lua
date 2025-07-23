local commons = require('handofgod.commons')
local utils = require('handofgod.utils')
local ns = vim.api.nvim_create_namespace("HOGManagerHL")

local function getcolor(group,attr)
    return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)),attr)
end

vim.api.nvim_set_hl(0,"HOGDiffAdd", {
    bg = getcolor("DiffAdd","fg#"),
    fg = getcolor("Normal","bg#"),
    bold = true
})

vim.api.nvim_set_hl(0,"HOGDiffDelete", {
    bg = getcolor("DiffDelete","fg#"),
    fg = getcolor("Normal","bg#"),
    bold = true
})

local M = {
    keybinds = {
        confirm = 'y',
        cancel  = 'n',
    }
}

function M.spawn(additions, deletions, confirmation_callback, cancellation_callback)
    local list = utils.merge_list(additions, deletions)
    if #list == 0 then return end

    local mod = commons:create_window('Save? y/n')
    vim.api.nvim_buf_set_lines(mod.buf, 0, -1, false, list)
    M.set_buf_properties(mod.buf, #additions, #deletions)

    utils.kmap('n', M.keybinds.confirm, function()
        confirmation_callback()
        vim.api.nvim_win_close(mod.win, true)
    end, {buffer = mod.buf, nowait = true, noremap = true})

    utils.kmap('n', M.keybinds.cancel, function()
        cancellation_callback()
        vim.api.nvim_win_close(mod.win, true)
    end, {buffer = mod.buf, nowait = true, noremap = true})
end

function M.set_buf_properties(buf, adds, subs)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].modifiable = false
    vim.bo[buf].swapfile = false

    if adds > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
            end_row = adds,
            hl_eol = true,
            hl_group = 'HOGDiffAdd',
            sign_text = '+',
            sign_hl_group = 'HOGDiffAdd'
        })
    end

    if subs > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, adds, 0, {
            end_row = adds + subs,
            hl_eol = true,
            hl_group = 'HOGDiffDelete',
            sign_text = '-',
            sign_hl_group = 'HOGDiffDelete',
        })
    end
end

return M
