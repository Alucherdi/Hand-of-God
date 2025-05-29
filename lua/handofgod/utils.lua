local M = {}

function M.kmap(mode, hotkey, func, config)
    local hktype = type(hotkey)
    if hktype == 'string' then
        vim.keymap.set(mode, hotkey, func, config or {})
    elseif hktype == 'table' then
        for _, hk in ipairs(hotkey) do
            vim.keymap.set(mode, hk, func, config or {})
        end
    end
end

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

function M.merge_list(t1, t2)
  local result = {}
  for _, v in ipairs(t1) do table.insert(result, v) end
  for _, v in ipairs(t2) do table.insert(result, v) end
  return result
end

function M.map(list, f)
    local result = {}
    for i, v in ipairs(list) do
        result[i] = f(v)
    end
    return result
end

return M
