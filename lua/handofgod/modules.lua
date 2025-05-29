local commons = require('handofgod.commons')
local M = {
    modules = {
        manager  = {win = nil, buf = nil, is_active = false},
        jumper   = {win = nil, buf = nil, is_active = false},
        searcher = {win = nil, buf = nil, is_active = false},
        finder   = {win = nil, buf = nil, is_active = false}
    }
}

function M.switch(target)
    local mod = M.modules[target]
    if mod.is_active and vim.api.nvim_win_is_valid(mod.win) then return end

    for key, module in pairs(M.modules) do
        if key ~= target and module.is_active then
            commons.close(module)
            module.is_active = false
        end
    end

    mod.is_active = true
    return mod
end

return M
