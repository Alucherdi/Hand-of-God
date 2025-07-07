local data = require('handofgod.data')

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        file = vim.fn.fnamemodify(file, ':.')
        if vim.trim(file) == '' then return end

        local cursor = data.get_cursor(file)
        if not cursor then return end

        local _, _ = pcall(function() vim.api.nvim_win_set_cursor(0, cursor) end)
        -- if not success then print(_) end
    end
})

vim.api.nvim_create_autocmd("BufLeave", {
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        file = vim.fn.fnamemodify(file, ':.')

        if vim.trim(file) == '' then return end

        local cursor = vim.api.nvim_win_get_cursor(0)
        data.set_cursor(file, cursor)
    end
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function(_)
        local file = vim.api.nvim_buf_get_name(
            vim.api.nvim_get_current_buf())
        file = vim.fn.fnamemodify(file, ':.')

        if vim.trim(file) == '' then return end
        local cursor = vim.api.nvim_win_get_cursor(0)
        data.set_cursor(file, cursor)
    end
})
