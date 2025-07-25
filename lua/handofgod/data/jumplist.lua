local M = {
    datapath = vim.fn.stdpath('data') .. '/hog/',
    basename = string.gsub(vim.uv.cwd() or '', '/', '_'),
    file_count = 0,
    list = {},
    map = {},
}

function M.ensure_dir()
    if vim.fn.isdirectory(M.path) == 0 then
        vim.uv.fs_mkdir(M.datapath, 493)
    end
end

function M.load()
    M.path = M.datapath .. M.basename
    local file = io.open(M.path, 'r')
    if not file then return end

    local content = file:read('*a')
    file:close()

    pcall(function()
        M.list = vim.json.decode(content)
        print(M.list)
        M.gen_map()
    end)
end

function M.gen_map()
    M.map = {}
    for i, item in ipairs(M.list) do
        M.map[item.key] = {
            key = item,
            index = i,
            cursor = item.cursor,
        }
    end
end

function M.add(el)
    if M.map[el] then return end
    local ob = {
        key = el,
        cursor = vim.api.nvim_win_get_cursor(0)
    }

    table.insert(M.list, ob)
    ob.index = #M.list
    M.map[el] = ob
end

function M.get_cursor(path)
    return (M.map[path] or { cursor = nil }).cursor
end

function M.set_cursor(path, cursor)
    if M.map[path] then return end
    M.map[path].cursor = cursor
    M.list[M.map[path].index].cursor = cursor
end

function M.get_list()
    return M.list
end

function M.reorder_based_on(paths)
    M.list = {}
    vim.print(paths)
    for _, v in ipairs(paths) do
        local el = M.map[v]
        local o = {
            key = v,
            cursor = el and el.cursor or {1, 0},
        }

        table.insert(M.list, o)
    end
    M.gen_map()
end

function M.write()
    local file = io.open(M.path, 'w')
    if not file then return end

    file:write(vim.json.encode(M.list))
    file:close()
end

return M
