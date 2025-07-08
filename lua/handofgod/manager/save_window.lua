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

local function longest_name(list)
    local size = 9
    for _, v in ipairs(list) do
        if size < #v then size = #v end
    end

    return size
end

local M = {}

function M.spawn(additions, deletions, confirmation_callback)
    local list = utils.merge_list(additions, deletions)
    if #list == 0 then return end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
    M.set_buf_properties(buf, #additions, #deletions)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        title = 'Save? y/n',
        title_pos = 'center',
        border = 'single',
        style = 'minimal',
        width = longest_name(list), height = #list,
        row = 0, col = 0
    })

    utils.kmap('n', 'y', function()
        confirmation_callback()
        vim.api.nvim_win_close(win, true)
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
            hl_eol = true,
            hl_group = "HOGDiffAdd",
        })
    end

    if subs > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, adds, 0, {
            end_row = adds + subs,
            hl_eol = true,
            hl_group = "HOGDiffDelete",
        })
    end
end

return M
