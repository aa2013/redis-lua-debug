redis.call('set',KEYS[1],ARGV[1])
local json = cjson.encode({a=1,b=2})
return redis.call('get',KEYS[1])..','..json
