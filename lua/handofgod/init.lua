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

function M.create_window()
    M.buffer = vim.api.nvim_create_buf(false, true)

    local path = vim.fs.root(0, vim.fn.expand('%')) or ""
    path = path:gsub(vim.uv.cwd(), '.')

    M.initial_files = split(vim.fn.glob(path .. '/*'), '\r\n')

    vim.api.nvim_buf_set_lines(M.buffer, 0, 1, false, M.initial_files)

    M.window = vim.api.nvim_open_win(M.buffer, true, {
        border   = "rounded",
        relative = "editor",
        height = math.ceil(vim.o.lines / 4),
        width  = math.ceil(vim.o.columns),
        row = 0,
        col = math.ceil(vim.o.columns / 3),
    })
end

return M
