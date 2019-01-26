require ("ping")

local check_internet_every_s = 10

local internet_states = {
    working=1,
    unknown=2,
    unavialable=3,
    cis_off_internet_on=4,
    cis_on_internet_off=5,
    bigloss=6,
    smallloss=7,
    avialable=8 }

local internet_state_icon = {
    "/home/sheridan/.config/awesome/icons/FatCow/showel.png",
    "/home/sheridan/.config/awesome/icons/FatCow/asterisk_yellow.png",
    "/home/sheridan/.config/awesome/icons/FatCow/skull_old.png",
    "/home/sheridan/.config/awesome/icons/FatCow/dice.png",
    "/home/sheridan/.config/awesome/icons/FatCow/cross.png",
    "/home/sheridan/.config/awesome/icons/FatCow/chart_down_color.png",
    "/home/sheridan/.config/awesome/icons/FatCow/error_checking.png",
    "/home/sheridan/.config/awesome/icons/FatCow/green.png"
}

local internet_state_text = {
    "Проверяем...",
    "Пока непонятно...",
    "Инторнетов нет",
    "Кисы в отключке, но инторнет есть.",
    "Кисы живы, но инторнетов нет",
    "Большие потери",
    "Малые потери",
    "Всё ок, инторнеты есть"
}

local icon_widget = nil
local icon_widget_tooltip = nil

function make_internet_state(google, cis)
    if google == ping_states.avialable   and cis == ping_states.avialable   then return internet_states.avialable           end
    if google == ping_states.unavialable and cis == ping_states.unavialable then return internet_states.unavialable         end
    if google == ping_states.unavialable and cis == ping_states.avialable   then return internet_states.cis_on_internet_off end
    if google == ping_states.avialable   and cis == ping_states.unavialable then return internet_states.cis_off_internet_on end
    if google == ping_states.bigloss     or  cis == ping_states.bigloss     then return internet_states.bigloss             end
    if google == ping_states.smallloss   or  cis == ping_states.smallloss   then return internet_states.smallloss           end
    if google == ping_states.unknown     or  cis == ping_states.unknown     then return internet_states.unknown             end
end

function check_internet()
    return make_internet_state(ping_ip("8.8.8.8", check_internet_every_s), ping_ip("192.168.200.1", check_internet_every_s))
end

function change_internet_avialable_state(state)
    icon_widget.image        = internet_state_icon[state]
    icon_widget_tooltip.text = internet_state_text[state]
end

function get_internet_avialable_widget()
    if icon_widget == nil then
        icon_widget = wibox.widget {
            image  = internet_state_icon[1],
            resize = false,
            widget = wibox.widget.imagebox
        }
        icon_widget_tooltip = awful.tooltip({
            objects = { icon_widget },
            text    = internet_state_text[1]
            })
    end
    return icon_widget
end

function check_internet_avialable()
    change_internet_avialable_state(internet_states.working)
    change_internet_avialable_state(check_internet())
end

function init_internet_avialable()
    gears.timer {
        timeout   = check_internet_every_s,
        autostart = true,
        call_now  = true,
        callback  = check_internet_avialable
    }
end

-- print(check_internet())
-- print(get_state_icon(check_internet()))
