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

local cursors = get_cursors()

local function save_cursors()
    local file = io.open(cursorfile, 'w')
    if not file then return end
    file:write(vim.json.encode(cursors))
    file:close()
end


vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        local cursor = cursors[file]
        if not cursor then return end

        vim.api.nvim_win_set_cursor(0, cursor)
    end
})

vim.api.nvim_create_autocmd("BufLeave", {
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        local cursor = vim.api.nvim_win_get_cursor(0)
        cursors[file] = cursor
        save_cursors()
    end
})
