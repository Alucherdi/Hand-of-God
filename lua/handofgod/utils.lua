local M = {}

function M.remove_empties(tbl)
    for i, v in pairs(tbl) do
        if vim.trim(v) == '' then
            tbl[i] = nil
        end
    end
end

function M.get_diff(a, b)
    local b_set = {}
    for _, v in ipairs(b) do
        b_set[v] = true
    end

    local diff = {}
    for _, v in ipairs(a) do
        if not b_set[v] and vim.trim(v) ~= '' then
            table.insert(diff, v)
        end
    end

    return diff
end

function M.includes(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end

    return false
end

function M.index_of(tbl, value, key)
    for i, v in ipairs(tbl) do
        if key then
            if v[key] == value then return i end
        else
            if v == value then return i end
        end
    end

    return -1
end

return M
