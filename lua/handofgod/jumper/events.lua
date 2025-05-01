local M = {}

local datapath = vim.fn.stdpath('data') .. '/hog/'
local cwd = string.gsub(vim.uv.cwd() or '', '/', '_')
local cursorfile = datapath .. cwd .. '__cursors'

local function get_cursors()
    local file = io.open(cursorfile, 'r')
    if not file then
        return {}
    end

    local content = file:read('*a')
    file:close()

    return vim.json.decode(content)
end

M.cursors = get_cursors()

function M.save_cursors()
    local file = io.open(cursorfile, 'w')
    if not file then return end
    file:write(vim.json.encode(M.cursors))
    file:close()
end

function M.clean_cursors(list)
    for _, v in ipairs(list) do
        M.cursors[v] = nil
    end
end


vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        file = vim.fn.fnamemodify(file, ':.')

        local cursor = M.cursors[file]
        if not cursor then return end

        vim.api.nvim_win_set_cursor(0, cursor)
    end
})

vim.api.nvim_create_autocmd("BufLeave", {
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        file = vim.fn.fnamemodify(file, ':.')

        if vim.trim(file) == '' then return end

        local cursor = vim.api.nvim_win_get_cursor(0)
        M.cursors[file] = cursor
        M.save_cursors()
    end
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function(_)
        local file = vim.api.nvim_buf_get_name(
            vim.api.nvim_get_current_buf())
        file = vim.fn.fnamemodify(file, ':.')

        if vim.trim(file) == '' then return end
        local cursor = vim.api.nvim_win_get_cursor(0)
        M.cursors[file] = cursor
        M.save_cursors()
    end
})

return M
