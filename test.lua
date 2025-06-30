local async = require('async')
local spawner = require('spawner')

local aborted = false

local win, buf, thread

local function create_buffer()
    buf = vim.api.nvim_create_buf(false, true)
    win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        height = 12,
        width = 80,
        row = 0, col = 0
    })

    vim.api.nvim_create_autocmd('bufLeave', {
        buffer = buf,
        callback = function()
            spawner.stop()
            aborted = true

            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end
    })

    vim.keymap.set('n', '<C-y>', function()
        spawner.stop()
        aborted = true
    end, {buffer = buf})
end

local function list(elements)
    local co = coroutine.running()
    if not co then return end
    if aborted then
        error('Coroutine aborted')
    end

    vim.schedule(function()
        vim.api.nvim_buf_set_lines(buf, -2, -1, false, elements)
        coroutine.resume(co)
    end)

    coroutine.yield()
end

local function execute_command()
    aborted = false
    local command = 'rg'
    local args = {'--vimgrep', 'n', vim.fn.expand('$HOME')}

    spawner.execute(
        command, args,
        function(data)
            local co = coroutine.create(function()
                if data == nil then return {} end
                local lines = vim.split(data, '\n', {trimempty = true, plain = true})
                list(lines)
            end)
           local res = coroutine.resume(co)
           if not res then return end
        end
   )
end

local function main()
    create_buffer()
    execute_command()
end

main()
