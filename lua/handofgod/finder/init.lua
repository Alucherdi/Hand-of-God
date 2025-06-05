local commons = require('handofgod.commons')
local utils = require('handofgod.utils')
local mod = require('handofgod.modules')
local ft = require('handofgod.data.filetype')

local ns = vim.api.nvim_create_namespace("HOGFinderHL")
local cwd = vim.uv.cwd()

local command = {
    'rg',
    '-i',
    '--vimgrep',
    '--only-matching',
    '--field-match-separator=' .. commons.separator
}

local M = {
    index = 1,
    list = { paths = {}, positions = {} },
    process = nil,

    preview = nil,
    paths = nil,
    prompt = nil
}

function M.setup(config) end

function M.open()
    M.gen_paths_module()
    M.gen_preview_module()
    M.gen_prompt_module()
end

function M.gen_prompt_module()
    M.prompt = mod.switch('finder')

    M.prompt.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'prompt', {buf = M.prompt.buf})
    M.prompt.win = commons:create_window('input', M.prompt.buf, {
        style = 'minimal', row = 15, col = 0, height = 1
    })
    vim.fn.prompt_setprompt(M.prompt.buf, '')

    utils.kmap('i', '<Esc>', function() commons.close(M.prompt) end, {buffer = M.prompt.buf})
    utils.kmap('i', '<C-n>', function() M.move_to(1) end)
    utils.kmap('i', '<C-p>', function() M.move_to(-1) end)

    vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = M.prompt.buf,
        callback = function(_)
            M.index = 1
            local row, _ = unpack(vim.api.nvim_win_get_cursor(M.prompt.win))
            local line = vim.api.nvim_buf_get_lines(M.prompt.buf, row - 1, row, false)[1]

            if vim.trim(line) == '' then return end
            M.gen_data(line)
        end
    })

    vim.api.nvim_create_autocmd('bufLeave', {
        buffer = M.prompt.buf,
        callback = function()
            vim.api.nvim_win_close(M.paths.win, true)
            vim.api.nvim_win_close(M.preview.win, true)
        end
    })

    vim.cmd('startinsert')
end

function M.move_to(dir)
    M.index = M.index + dir
    local count = #vim.api.nvim_buf_get_lines(M.paths.buf, 0, -1, false)
    if M.index > count then M.index = count; return end
    if M.index < 1 then M.index = 1; return end

    print(M.list.paths[M.index])

    vim.api.nvim_win_set_cursor(M.paths.win, {M.index, 0})
    M.gen_preview()
end

function M.gen_preview_module()
    M.preview = {}
    M.preview.buf = vim.api.nvim_create_buf(false, true)

    vim.bo[M.preview.buf].buftype = 'nofile'
    vim.bo[M.preview.buf].bufhidden = 'wipe'
    vim.bo[M.preview.buf].swapfile = false

    vim.api.nvim_buf_set_lines(M.preview.buf, 0, -1, false, {})

    M.preview.win = commons:create_window('', M.preview.buf, {
        style = 'minimal',
        row = 11,
        height = 4,
    })

    vim.cmd('set cursorline')
end

function M.gen_paths_module()
    M.paths = {}
    M.paths.buf = vim.api.nvim_create_buf(false, true)

    vim.bo[M.paths.buf].buftype = 'nofile'
    vim.bo[M.paths.buf].bufhidden = 'wipe'
    vim.bo[M.paths.buf].swapfile = false

    vim.api.nvim_buf_set_lines(M.paths.buf, 0, -1, false, {})

    M.paths.win = commons:create_window('Finder', M.paths.buf, {
        style = 'minimal',
        height = 10,
    })

    vim.cmd('set cursorline')
end

function M.gen_data(search)
    M.list.paths = {}
    M.list.positions = {}

    if M.process and M.process.kill then
        M.process:kill('sigterm')
        M.process = nil
    end

    local c = utils.merge_list(command, {search, cwd})
    local line_num = 0

    M.process = vim.system(c, {
        stdout = function(_, data)
            if not data then return end
            for _, line in ipairs(vim.split(data, '\n', {trimempty = true})) do
                vim.schedule(function()
                    local path, srow, scol, match = unpack(vim.split(
                        line, commons.separator,
                        {trimempty = true, plain = true}))

                    if match == nil then return end
                    local row = tonumber(srow)
                    local col = tonumber(scol)

                    table.insert(M.list.paths, vim.fn.fnamemodify(path, ':.'))
                    table.insert(M.list.positions, {row, col, col + #match})

                    if vim.api.nvim_buf_is_valid(M.paths.buf) then
                        vim.api.nvim_buf_set_lines(M.paths.buf, 0, -1, false, M.list.paths)
                        vim.api.nvim_win_set_config(M.paths.win, {
                            title = 'Finder ' .. M.index .. '/' .. #M.list.paths,
                        })
                    end

                    if line_num == 0 then
                        M.gen_preview()
                    end

                    line_num = line_num + 1
                end)
            end
        end
    })
end

function M.gen_preview()
    if not vim.api.nvim_buf_is_valid(M.paths.buf) then return end

    local row, _ = unpack(vim.api.nvim_win_get_cursor(M.paths.win))
    local path = vim.api.nvim_buf_get_lines(M.paths.buf, row - 1, row, false)[1]

    local file = vim.fn.readfile(path)
    vim.api.nvim_buf_set_lines(M.preview.buf, 0, 1, false, file)

    local filetype = ft.detect(path or '')
    vim.api.nvim_set_option_value('filetype', filetype, {buf = M.preview.buf})

    local positions = M.list.positions[M.index]
    vim.api.nvim_win_set_cursor(M.preview.win, {positions[1], positions[2]})
    vim.api.nvim_win_call(M.preview.win, function() vim.cmd('normal! zz') end)

    vim.api.nvim_buf_set_extmark(M.preview.buf, ns, positions[1] - 1, positions[2] - 1, {
        end_col = positions[3] - 1,
        end_row = positions[1] - 1,
        hl_group = "CurSearch"
    })
end

return M
