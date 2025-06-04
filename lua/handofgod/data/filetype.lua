local M = {}
M.cache = {}

function M.detect(path)
    return vim.filetype.match({filename = path}) or 'plaintext'
end

return M
