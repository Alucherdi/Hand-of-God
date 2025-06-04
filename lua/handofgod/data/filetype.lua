local M = {}
M.cache = {}

function M.detect(path)
    if M.cache[path] then return M.cache[path] end
    local buf = vim.fn.bufadd(path)
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    vim.fn.bufload(buf)

    local ft = vim.bo[buf].filetype
    vim.api.nvim_buf_delete(buf, {force = true})
    M.cache[path] = ft or 'plaintext'
    return M.cache[path]
end

return M
