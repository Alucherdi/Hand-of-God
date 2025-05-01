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
        if not b_set[v] then
            table.insert(diff, v)
        end
    end

    return diff
end

return M
