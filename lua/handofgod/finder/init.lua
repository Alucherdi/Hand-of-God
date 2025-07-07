local spawner = require('handofgod.helpers.spawner')
local commons = require('handofgod.commons')

local aborted = false

local M = {
    prompt = {},
    pattern = '',
    line_cap = 10000,
    exceeded = false,
}

function M.setup(config)
end

function M.open()
    M.prompt, M.main = commons.create_prompted_window('Greper', '')
    M.main.list = { size = 0 }

    M.manage_list()
    M.manage_prompt()
end

function M.close()
    M.abort()

    M.close_module(M.prompt)
    M.close_module(M.main)

    vim.api.nvim_input("<esc>")
end

function M.close_module(module)
    if vim.api.nvim_buf_is_valid(module.buf) then
        vim.api.nvim_buf_delete(module.buf, {force = true})
    end

    if vim.api.nvim_win_is_valid(module.win) then
        vim.api.nvim_win_close(module.win, true)
    end
end

function M.abort()
    spawner.stop()
    aborted = true
end

function M.manage_prompt()
    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = M.prompt.buf,
        callback = function(_)
            local row, _ = unpack(vim.api.nvim_win_get_cursor(M.prompt.win))
            M.pattern = vim.api.nvim_buf_get_lines(M.prompt.buf, row - 1, row, false)[1]
        end
    })

    vim.keymap.set('i', '<Esc>', function()
        M.close()
    end, {buffer = M.prompt.buf})

    vim.keymap.set('i', '<CR>', function()
        M.execute_command(M.pattern)
        vim.api.nvim_set_current_win(M.main.win)
    end, {buffer = M.prompt.buf})


    vim.api.nvim_set_current_win(M.prompt.win)
    vim.cmd('startinsert')
end

function M.goto(path, cursor)
    vim.cmd('edit ' .. path)
    vim.api.nvim_win_set_cursor(0, cursor)
end

function M.manage_list()
    local options = vim.bo[M.main.buf]

    options.buftype = 'nowrite'
    options.bufhidden = 'wipe'
    options.swapfile = false

    vim.keymap.set('n', 'q', function() M.close() end, {buffer = M.main.buf})
    vim.keymap.set('n', '<Esc>', function() M.close() end, {buffer = M.main.buf})

    vim.keymap.set('n', '<CR>', function()
        local row = vim.api.nvim_win_get_cursor(M.main.win)[1]
        local line = vim.api.nvim_buf_get_lines(M.main.buf, row - 1, row, false)[1]
        local path, matchrow, matchcol, _ = unpack(vim.split(line, ':', {plain = true}))
        M.close()

        M.goto(path, {tonumber(matchrow), tonumber(matchcol)})
    end, {buffer = M.main.buf})

    vim.keymap.set('n', '<C-f>', function()
        vim.api.nvim_set_current_win(M.prompt.win)
    end, {buffer = M.main.buf})

    vim.o.cursorline = true
end

function M.list(elements)
    local co = coroutine.running()
    if not co then return end
    if aborted then
        error('Coroutine aborted')
    end

    vim.schedule(function()
        if vim.api.nvim_win_is_valid(M.main.win) then
            vim.api.nvim_win_set_config(M.main.win, {
                title = 1 .. '/' .. M.main.list.size,
            })
        end

        if M.main.list.size >= M.line_cap then
            M.exceeded = true
            if vim.api.nvim_buf_is_valid(M.main.buf) then
                vim.api.nvim__redraw({win = M.main.win, flush = true})
            end
        else
            if vim.api.nvim_buf_is_valid(M.main.buf) then
                vim.api.nvim_buf_set_lines(M.main.buf, M.main.list.size, -1, false, elements)
                vim.api.nvim__redraw({win = M.main.win, flush = true})
            end
        end


        M.main.list.size = M.main.list.size + #elements
        coroutine.resume(co)
    end)


    coroutine.yield()
end

function M.execute_command(pattern)
    M.main.list.size = 0
    aborted = false

    vim.api.nvim_win_set_config(M.main.win, {
        title = '',
    })

    vim.api.nvim_buf_set_lines(M.main.buf, 0, -1, false, {})
    local command = 'rg'
    local args = {'--vimgrep', '-i', pattern}

    spawner.execute(
        command, args,
        function(data)
            local co = coroutine.create(function()
                if data == nil then return end
                local lines = vim.split(data, '\n', {trimempty = true, plain = true})
                M.list(lines)
            end)
           local res = coroutine.resume(co)
           if not res then return end
        end
   )
end

return M
