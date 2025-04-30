local M = {
    dataPath = vim.fn.stdpath('data') .. '/hog/',
    key = string.gsub(vim.uv.cwd() or '', '/', '_'),
    list = {}
}
M.path = M.dataPath .. M.key

local function contains(tbl, item)
    for i, v in pairs(tbl) do
        if v == item then return true end
    end

    return false
end

local function ensure_directory(path)
    if vim.fn.isdirectory(path) == 0 then
        vim.loop.fs_mkdir(path, 493)
    end
end

function M.load()
    ensure_directory(M.dataPath)

    local file = io.open(M.path, "r")

    if not file then
        M.list[M.key] = {}
        return false
    end

    local content = file:read("*a")
    file:close()

    M.list[M.key] = vim.split(content, '\n', { trimempty = true })
    return true
end

function M.add()
    local currentFile = vim.fn.expand('%')

    if not M.list[M.key] then
        M.list[M.key] = {}
    end

    if not contains(M.list[M.key], currentFile) then
        table.insert(M.list[M.key], currentFile)

        local file = io.open(M.path, "a")
        if not file then return nil end

        file:write(currentFile .. '\n')
        file:close()
    end
end

function M.jump_to(index)
    local path = M.list[M.key][index]
    if path == nil then
        return
    end

    vim.cmd("edit " .. vim.fn.expand(path))
end

function M.rewrite(buffer)
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    local file = io.open(M.path, "w")
    if not file then return nil end

    file:write(table.concat(lines, '\n'))
    file:close()

    M.load()
end

function M.explore()
    M.host = vim.api.nvim_get_current_win()

    local buffer = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(buffer, 0, 1, false, M.list[M.key])

    M.window = vim.api.nvim_open_win(buffer, true, {
        border   = "rounded",
        relative = "editor",
        height = math.ceil(vim.o.lines / 4),
        width  = math.ceil(vim.o.columns / 4),
        row = 0,
        col = math.ceil(vim.o.columns / 3),
    })

    vim.keymap.set('n', '<CR>', function()
        M.rewrite(buffer)
        vim.api.nvim_win_close(M.window, true)
        vim.api.nvim_buf_delete(buffer, { force = true })
    end, { buffer = buffer })

    vim.keymap.set('n', '<Esc>', function()
        M.rewrite(buffer)
        vim.api.nvim_win_close(M.window, true)
        vim.api.nvim_buf_delete(buffer, { force = true })
    end, { buffer = buffer })
end

function M.show()
    print(vim.inspect(M.list))
end

function M.init()
    M.load()
    M.host = vim.api.nvim_get_current_win()
end

M.init()
return M
