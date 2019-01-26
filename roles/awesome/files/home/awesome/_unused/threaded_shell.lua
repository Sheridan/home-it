lanes = require("lanes").configure()
-- s = require('socket')
local shells = {}


function ts_worker(linda, sh, refresh_timeout)
    -- local ntime = os.clock()-1
    s = require("socket")
    while true do
        -- if os.clock() > ntime then
            -- print(".")
            local f = io.popen(sh)
            linda:send('!', f:read("*all"))
            f:close()
            -- ntime = os.clock() + refresh_timeout
        -- end
        s.sleep(refresh_timeout)
    end
end

function ts_run(name, refresh_timeout, sh)
    shells[name]    = {
        worker      = lanes.gen('*', ts_worker),
        linda       = lanes.linda(),
        prev_answer = nil
    }
    shells[name]["worker_thread"] = shells[name].worker(shells[name].linda, sh, refresh_timeout)
end

function ts_query(name, default)
    local timeout = 0.02
    local _, answer = shells[name].linda:receive(timeout, '!')
    if answer then
        shells[name].prev_answer = answer
    end
    if shells[name].prev_answer then
        return shells[name].prev_answer
    end
    return default
end

-- function sh_debug_init()
--     ts_run('ls', 1, "ping 8.8.8.8 -nqc10 -i0.2 | grep loss | sed -r 's@.* ([0-9]*)% .*@\\1@'")
-- end

-- function sh_debug_show()
--     print(ts_query('ls'))
-- end

-- function sh_debug()
--     sh_debug_init()
--     sh_debug_show()
-- end
-- "ping 8.8.8.8 -nqc10 -i0.2 | grep loss | sed -r 's@.* ([0-9]*)% .*@\\1@'"
