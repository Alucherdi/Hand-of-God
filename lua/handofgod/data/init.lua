local M = {
    datapath = vim.fn.stdpath('data') .. '/hog/',
    basename = string.gsub(vim.uv.cwd() or '', '/', '_'),
    list = {}
}

M.path = M.datapath .. M.basename

function M.ensure_dir()
    if vim.fn.isdirectory(M.path) == 0 then
        vim.loop.fs_mkdir(M.path, 493)
    end
end

function M.load()
    local file = io.open(M.path, 'r')
    if not file then return {} end

    local content = file:read('*a')
    file:close()

    pcall(function() M.list = vim.json.decode(content) end)
end

function M.write()
    local file = io.open(M.path, 'w')
    if not file then return end

    file:write(vim.json.encode(M.list))
    file:close()
end

function M.add(element)
    local map = M.to_map()
    if map[element] then return end
    table.insert(M.list, {key = element, cursor = vim.api.nvim_win_get_cursor(0)})
    M.write()
end

function M.to_map()
    local map = {}
    for _, item in ipairs(M.list) do
        map[item.key] = item
    end
    return map
end

function M.reorder_based_on(list)
    local map = M.to_map()
    M.list = {}

    for _, item in ipairs(list) do
        table.insert(M.list, {key = item, cursor = map[item].cursor or { 1, 0 }})
    end
end

function M.get_cursor(key)
    local cursor = nil
    for _, item in ipairs(M.list) do
        if key == item.key then
            cursor = item.cursor
        end
    end

    return cursor
end

function M.set_cursor(key, cursor)
    for _, item in ipairs(M.list) do
        if key == item.key then
            item.cursor = cursor
            break
        end
    end

    M.write()
end

function M.get_files()
    local files = {}
    for _, item in ipairs(M.list) do
        table.insert(files, item.key)
    end

    return files
end

return M
