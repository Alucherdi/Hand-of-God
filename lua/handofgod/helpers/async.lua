local M = {}

local pack = function(...)
    return { n = select('#', ...), ... }
end

local empty_func = function(...) end

local get_arg = function(n, ...)
    return pack(...)[n]
end

local next_step = function(step, thread, callback, ...)
    local status = get_arg(1, ...)
    if not status then
        error('')
    end

    if coroutine.status(thread) == 'dead' then
        (callback or empty_func)(select(2, ...))
    else
        local future = get_arg(2, ...)
        future(step)
    end
end

local execute = function(future, callback)
    local thread = coroutine.create(future)
    local step
    step = function(...)
        next_step(step, thread, callback, coroutine.resume(thread, ...))
    end

    step()
end


local async = function(func)
    return function(...)
        local args = pack(...)
        local function future(step)
            if step == nil then
                return func(unpack(args))
            else
                execute(future, step)
            end
        end

        return future
    end
end

M.create = function(func)
    return async(func)
end

return M
