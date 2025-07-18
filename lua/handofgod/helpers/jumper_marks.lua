local data = require('handofgod.data')
local utils = require('handofgod.utils')

local M = {
    marks = {}
}

function M.set_manager_marks(buf, ns, paths)
    for i, v in ipairs(paths) do
        local index = utils.index_of(data.list, v, 'key')
        if index ~= -1 then
            M.set_mark_at(buf, ns, i, index)
        end
    end
end

function M.set_searcher_marks(buf, ns)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    for i, v in ipairs(lines) do
        local index = utils.index_of(data.list, v, 'key')
        if index ~= -1 then
            M.set_mark_at(buf, ns, i, index)
        end
    end
end

function M.set_mark_at(buf, ns, index, jumper_index)
    jumper_index = jumper_index or #data.list
    local current = M.marks[index]

    local opts = {
        virt_text = {{'(J' .. jumper_index .. ')', 'Special'}},
        virt_text_pos = 'eol',
    }

    if current then
        opts.id = current
    end

    local i = vim.api.nvim_buf_set_extmark(buf, ns, index, 0, opts)

    if not current then
        M.marks[index] =  i
    end
end

function M.remove_marks(buf, ns)
    for _, v in pairs(M.marks) do
        vim.api.nvim_buf_del_extmark(buf, ns, v)
    end

    M.marks = {}
    vim.print(M.marks)
end

function M.remove_mark_at(buf, ns, index)
    vim.api.nvim_buf_del_extmark(buf, ns, M.marks[index])
end

return M
