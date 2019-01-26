require("threaded_shell")

ping_states = { unknown=1, unavialable=2, bigloss=3, smallloss=4, avialable=5 }

local ping_state_icon = {
    "/home/sheridan/.config/awesome/icons/FatCow/asterisk_yellow.png",
    "/home/sheridan/.config/awesome/icons/FatCow/delete.png",
    "/home/sheridan/.config/awesome/icons/FatCow/exclamation.png",
    "/home/sheridan/.config/awesome/icons/FatCow/error_checking.png",
    "/home/sheridan/.config/awesome/icons/FatCow/green.png"
}

local ping_state_sound = {
    "/home/sheridan/.config/awesome/sounds/Scrape_S-S_Bainbr-7977_hifi.mp3",
    "/home/sheridan/.config/awesome/sounds/StoogeOrgan.mp3",
    "/home/sheridan/.config/awesome/sounds/Clink-Intermed-476_hifi.mp3",
    "/home/sheridan/.config/awesome/sounds/slide1a-Transluc-7808_hifi.mp3",
    "/home/sheridan/.config/awesome/sounds/Energy-Mystery-8894_hifi.mp3",
}

local ping_results = {}

function make_ping_state(result)
    if result == -1                   then return ping_states.unknown     end
    if result ==  0                   then return ping_states.avialable   end
    if result >   0  and result <= 50 then return ping_states.smallloss   end
    if result >   50 and result <= 90 then return ping_states.bigloss     end
    if result >   90                  then return ping_states.unavialable end
    return ping_states.unavialable
end

function ping_ip(ip, timeout)
    local name = "ping_" .. ip
    if not ping_results[name] then
        ts_run(name, timeout, "ping " .. ip .. " -nqc10 -i0.2 | grep loss | sed -r 's@.* ([0-9]*)% .*@\\1@'")
        ping_results[name] = { state=ping_states.unknown }
    end
    local state = make_ping_state(ts_query(name, -1)+0)
    if state ~= ping_results[name].state then
        ping_results[name].state = state
        awful.spawn("play -q " .. ping_state_sound[state])
    end
    return state
end

function get_state_icon(state)
    -- print(state)
    return ping_state_icon[state]
end
