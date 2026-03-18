local redis = require('redis')
local cjson = require('cjson')

local client
local redis_env = {}
function redis_env.connect(params)
    client = redis.connect(params)
    if params.password then
        client:auth('redis!2#')
    end
    client:select(params.db)
end

function redis_env.call(cmd, ...)
    cmd = string.lower(cmd)

    local fn = client[cmd]
    if not fn then
        error("unknown redis command: " .. cmd)
    end

    return fn(client, ...)
end

function redis_env.pcall(cmd, ...)
    local ok, res = pcall(redis_env.call, cmd, ...)

    if ok then
        return res
    else
        return { err = res }
    end
end

local function createSandbox(keys, argv)
    local scope = {
        -- 注入 Redis 接口
        redis = redis,

        -- Redis 标准变量
        KEYS = keys or {},
        ARGV = argv or {},

        -- 基础安全函数（白名单）
        ipairs = ipairs,
        pairs = pairs,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        string = string,
        table = table,
        math = math,
        unpack = unpack or table.unpack,
        cjson = cjson
    }

    local env = setmetatable(scope, {
        __index = _G,
        __newindex = function(_, k)
            error("global '" .. k .. "' is readonly", 2)
        end
    })

    return env
end
function redis_env.runLuaFile(path, keys, argv)
    local env = createSandbox(keys, argv)

    env.redis.call = function(cmd, ...)
        return redis_env.call(cmd, ...)
    end

    local func, err = loadfile(path, "t", env)
    if not func then
        error(err)
    end

    return func()
end
return redis_env
