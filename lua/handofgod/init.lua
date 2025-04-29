local M = {}

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function gen_list()
    local files = {}
    local directories = {}

    local bufferPath = vim.fn.expand('%:p:h')
    local list = vim.fn.globpath(bufferPath, '*', false, true)

    for _, item in pairs(list) do
        local stat = vim.loop.fs_stat(item)
        if stat then
            if stat.type == 'file' then
                table.insert(files, vim.fn.fnamemodify(item, ':.'))
            end

            if stat.type == 'directory' then
                table.insert(directories, vim.fn.fnamemodify(item, ':.') .. '/')
            end
        end
    end

    return {
        files = files,
        directories = directories
    }
end

function M.create_window()
    local items = gen_list()
    local list = vim.tbl_extend('keep', items.directories, items.files)

    M.buffer = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(M.buffer, 0, 1, false, list)

    M.window = vim.api.nvim_open_win(M.buffer, true, {
        border   = "rounded",
        relative = "editor",
        height = math.ceil(vim.o.lines / 4),
        width  = math.ceil(vim.o.columns),
        row = 0,
        col = math.ceil(vim.o.columns / 3),
    })
end

function M:open()
end

return M
