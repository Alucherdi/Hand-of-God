local spawner = require('handofgod.helpers.spawner')

local aborted = false
local main = {
    offset = {x = 20, y = 10},
    list = {size = 0},
}

main.height = vim.o.lines - (main.offset.y * 2)
main.width  = vim.o.columns - (main.offset.x * 2)

local prompt = {
    width = main.width,
    height = 1
}

prompt.offset = {
    x = main.offset.x,
    y = main.offset.y - 3
}

local M = {
    main = main,
    prompt = prompt,
    pattern = ''
}

function M.setup(config)
end

function M.open()
    M.create_list()
    M.create_prompt()
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

function M.create_prompt()
    M.prompt.buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_set_option_value('buftype', 'prompt', {buf = M.prompt.buf})
    vim.fn.prompt_setprompt(M.prompt.buf, '')

    M.prompt.win = vim.api.nvim_open_win(M.prompt.buf, true, {
        relative = 'editor',
        style = 'minimal',
        border = 'single',
        width = M.prompt.width,
        height = M.prompt.height,
        title = 'Grep',
        title_pos = 'center',
        col = M.prompt.offset.x,
        row = M.prompt.offset.y
    })

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
        M.close_module(M.prompt)
    end, {buffer = M.prompt.buf})


    vim.cmd('startinsert')
end

function M.goto(path, cursor)
    vim.cmd('edit ' .. path)
    vim.api.nvim_win_set_cursor(0, cursor)
end

function M.create_list()
    M.main.buf = vim.api.nvim_create_buf(false, true)
    local options = vim.bo[M.main.buf]

    options.buftype = 'nowrite'
    options.bufhidden = 'wipe'
    options.swapfile = false

    M.main.win = vim.api.nvim_open_win(M.main.buf, true, {
        relative = 'editor',
        style = 'minimal',
        border = 'single',
        height = M.main.height,
        width = M.main.width,
        row = M.main.offset.y,
        col = M.main.offset.x
    })

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
        M.create_prompt()
        vim.api.nvim_buf_set_lines(M.prompt.buf, 0, -1, false, {M.pattern})
        vim.api.nvim_win_set_cursor(M.prompt.win, {1, #M.pattern})
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
        if vim.api.nvim_buf_is_valid(M.main.buf) then
            vim.api.nvim_buf_set_lines(M.main.buf, M.main.list.size, -1, false, elements)
            vim.api.nvim__redraw({win = M.main.win, flush = true})
        end

        M.main.list.size = M.main.list.size + #elements

        if vim.api.nvim_win_is_valid(M.main.win) then
            vim.api.nvim_win_set_config(M.main.win, {
                title = 1 .. '/' .. M.main.list.size,
            })
        end

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
