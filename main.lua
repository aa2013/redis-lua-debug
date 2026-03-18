--#region 定义库路径
package.cpath = "./libs/5.4/lib/?.dll;"
package.path = "./libs/5.4/lua/?.lua;./libs/redis/?.lua;./?.lua"
--#endregion
local redis = require('redis_env')

local params = {
    host = '127.0.0.1',
    port = 6378,
    password = 'redis!2#',
    db = 0,
}
redis.connect(params)

--
local test_file = './test/test2.lua'
local keys = { 'key1' }
local argv = { '111112' }
local result = redis.runLuaFile(test_file, keys, argv)
if type(result) == 'table' then
    print(table.unpack(result))
else
    print(result)
end