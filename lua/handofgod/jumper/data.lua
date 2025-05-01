local M = {
    path = vim.fn.stdpath('data') .. '/hog/',
    key = string.gsub(vim.uv.cwd() or '', '/', '_'),
}

M.file = M.path .. M.key

function M.ensure_dir()
    if vim.fn.isdirectory(M.path) == 0 then
        vim.loop.fs_mkdir(M.path, 493)
    end
end

function M.read()
    local file = io.open(M.file, 'r')

    if not file then
        return {}
    end

    local content = file:read('*a')
    file:close()

    return vim.json.decode(content)
end

function M.write(data)
    local file = io.open(M.file, 'w')
    if not file then return end

    file:write(vim.json.encode(data))
    file:close()
end

M.ensure_dir()
return M
