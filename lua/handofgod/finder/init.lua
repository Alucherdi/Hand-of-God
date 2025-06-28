local spawner = require('handofgod.helpers.spawner')

local aborted = false
local main = {
    offset = {x = 14, y = 10},
    list = {size = 0},
}
main.height = vim.o.lines - (10 * 2)
main.width  = vim.o.columns - (14 * 2)

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

    vim.api.nvim_create_autocmd('bufLeave', {
        buffer = M.prompt.buf,
        callback = function()
            M.abort()
            if vim.api.nvim_win_is_valid(M.prompt.win) then
                vim.api.nvim_win_close(M.prompt.win, true)
            end

            vim.api.nvim_buf_delete(M.main.buf, {force = true})
            if vim.api.nvim_win_is_valid(M.main.win) then
                vim.api.nvim_win_close(M.main.win, true)
            end

            vim.api.nvim_input("<esc>")
        end
    })

    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = M.prompt.buf,
        callback = function(_)
            local row, _ = unpack(vim.api.nvim_win_get_cursor(M.prompt.win))
            M.pattern = vim.api.nvim_buf_get_lines(M.prompt.buf, row - 1, row, false)[1]
        end
    })

    vim.keymap.set('i', '<Esc>', function()
        vim.api.nvim_buf_delete(M.prompt.buf, {force = true})
        if vim.api.nvim_win_is_valid(M.prompt.win) then
            vim.api.nvim_win_close(M.prompt.win, true)
        end
    end, {buffer = M.prompt.buf})
    vim.keymap.set('i', '<C-n>', function() M.move_to(1) end, {buffer = M.prompt.buf})
    vim.keymap.set('i', '<C-p>', function() M.move_to(-1) end, {buffer = M.prompt.buf})
    vim.keymap.set('i', '<CR>', function() M.execute_command(M.pattern) end, {buffer = M.prompt.buf})
    vim.keymap.set('i', '<C-y>', function()
        local row = vim.api.nvim_win_get_cursor(M.main.win)[1]
        local line = vim.api.nvim_buf_get_lines(M.main.buf, row - 1, row, false)[1]
        local path, matchrow, matchcol, _ = unpack(vim.split(line, ':', {plain = true}))
        vim.api.nvim_buf_delete(M.prompt.buf, {force = true})
        if vim.api.nvim_win_is_valid(M.prompt.win) then
            vim.api.nvim_win_close(M.prompt.win, true)
        end

        M.goto(path, {tonumber(matchrow), tonumber(matchcol)})
    end, {buffer = M.prompt.buf})

    vim.cmd('startinsert')
end

function M.goto(path, cursor)
    vim.cmd('edit ' .. path)
    vim.api.nvim_win_set_cursor(0, cursor)
end

function M.create_list()
    M.main.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.main.buf].buftype = 'nofile'
    vim.bo[M.main.buf].bufhidden = 'wipe'
    vim.bo[M.main.buf].swapfile = false

    M.main.win = vim.api.nvim_open_win(M.main.buf, true, {
        relative = 'editor',
        style = 'minimal',
        border = 'single',
        height = M.main.height,
        width = M.main.width,
        row = M.main.offset.y,
        col = M.main.offset.x
    })

    vim.o.cursorline = true
end

function M.list(element)
    local co = coroutine.running()
    if not co then return end
    if aborted then
        error('Coroutine aborted')
    end

    vim.schedule(function()
        if vim.api.nvim_buf_is_valid(M.main.buf) then
            vim.api.nvim_buf_set_lines(M.main.buf, M.main.list.size, -1, false, {element})
        end

        M.main.list.size = M.main.list.size + 1

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
                for line in vim.gsplit(data, '\n', {trimempty = true, plain = true}) do
                    M.list(line)
                end
            end)
           local res = coroutine.resume(co)
           if not res then return end
        end
   )
end

function M.move_to(dir)
    local row = vim.api.nvim_win_get_cursor(M.main.win)[1] + dir
    local count = #vim.api.nvim_buf_get_lines(M.main.buf, 0, -1, false)

    if row > count then return end
    if row < 1 then return end

    vim.api.nvim_win_set_cursor(M.main.win, {row, 0})

    vim.api.nvim_win_set_config(M.main.win, {
        title = row .. '/' .. M.main.list.size,
    })
end

return M
