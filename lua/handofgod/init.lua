local M = {}

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
    M.host = vim.api.nvim_get_current_win()

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
    local line = vim.api.nvim_get_current_line()

    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.expand(line))
    vim.api.nvim_win_close(M.window, true)

    vim.api.nvim_buf_delete(M.buffer, { force = true })
end

return M
