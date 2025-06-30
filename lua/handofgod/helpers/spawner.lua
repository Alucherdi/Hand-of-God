local M = {
    process = nil,
    pid = nil,
    stdout = nil
}

function M.stop()
    if M.process then
        print(M.process:kill(9) or 'nil')
        M.process = nil
    end
end

function M.execute(command, args, on_success)
    M.stdout = vim.uv.new_pipe()

    M.process, M.pid = vim.uv.spawn(
        command, {
            cwd = vim.uv.cwd(),
            args = args,
            stdio = {nil, M.stdout, nil}
        },
        function(_, _) end
    )

    vim.uv.read_start(M.stdout, function(err, data)
        assert(not err, err)
        if not data then return end
        on_success(data)
    end)
end

return M
