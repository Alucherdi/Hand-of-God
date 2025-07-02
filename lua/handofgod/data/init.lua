local utils = require('handofgod.utils')
local M = {
    datapath = vim.fn.stdpath('data') .. '/hog/',
    basename = string.gsub(vim.uv.cwd() or '', '/', '_'),
    list = {}
}

M.path = M.datapath .. M.basename

function M.ensure_dir()
    if vim.fn.isdirectory(M.path) == 0 then
        local o = vim.uv.fs_mkdir(M.datapath, 493)
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
        local cursor = { 1, 0 }
        local map_i = map[item]
        if map_i and map_i.cursor then cursor = map_i.cursor end
        table.insert(M.list, {key = item, cursor = cursor})
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

function M.ls(path, ignore)
    local files = {}

    local hidden = vim.fn.globpath(path, '.*', false, true)
    local normal = vim.fn.globpath(path, '*', false, true)
    local list = vim.list_extend(normal, hidden)

    for _, item in pairs(list) do
        local rel = vim.fn.fnamemodify(item, ':t')

        if utils.includes(ignore, rel) then goto skip end
        if rel == '.' or rel == '..' then goto skip end

        local stat = vim.loop.fs_stat(item)
        if not stat then goto skip end

        if stat.type == 'directory' then
            table.insert(files, 1, rel .. '/')
        else
            table.insert(files, rel)
        end

        ::skip::
    end

    return files
end

return M
