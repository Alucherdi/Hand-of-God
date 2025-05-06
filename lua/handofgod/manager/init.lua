local commons = require('handofgod.commons')
local M = {}

local function gen_list(path)
    local files = {}

    local bufferPath = path or vim.fn.expand('%:p:h')
    local list = vim.fn.globpath(bufferPath, '*', false, true)

    for _, item in pairs(list) do
        local stat = vim.loop.fs_stat(item)
        local rel = vim.fn.fnamemodify(item, ':.')
        if stat then
            if stat.type == 'directory' then
                table.insert(files, 1, rel .. '/')
            end

            if stat.type == 'file' then
                table.insert(files, rel)
            end
        end
    end

    return files
end

function M:open()
    M.host = vim.api.nvim_get_current_win()

    local list = gen_list()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, list)

    local window = commons:create_window('Manager', buf)

    vim.keymap.set('n', '<Esc>', function()
        --local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        vim.api.nvim_win_close(window, true)
        vim.api.nvim_buf_delete(buf, { force = true })
    end, { buffer = buf })

end

function M:edit()
    local line = vim.api.nvim_get_current_line()

    vim.api.nvim_set_current_win(M.host)
    vim.cmd("edit " .. vim.fn.expand(line))
    vim.api.nvim_win_close(M.window, true)

    vim.api.nvim_buf_delete(M.buffer, { force = true })

end

return M
