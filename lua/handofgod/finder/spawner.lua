local uv = vim.uv
local cwd = uv.cwd()

local M = {
    process = nil,
    stdout  = nil,
    stderr  = nil,
}

function M.stop()
    if M.process then
        M.process:kill(9)
        M.process = nil
    end

    if M.stdout then
        uv.read_stop(M.stderr)
        uv.read_stop(M.stdout)
    end
end

function M.execute(command, args, on_success, on_err, on_exit)
    M.stop()
    M.stdout = uv.new_pipe()
    M.stderr = uv.new_pipe()

    ---@diagnostic disable-next-line: missing-fields
    M.process = uv.spawn(command, {
        args = args,
        stdio = {nil, M.stdout, M.stderr},
        cwd = cwd or '.',
        detached = true,
    }, function (code, signal)
        if on_exit then
            on_exit(code, signal)
        end
    end)

    uv.read_start(M.stderr, function(_, data)
        if on_err then
            on_err(data)
        end
    end)

    uv.read_start(M.stdout, function(_, data)
        if not data then return end
        on_success(data)
    end)
end

return M
