require("defines-global")
awful = require("awful")
if monitors_count > 1 then
    awful.spawn("xrandrapply.sh")
end


gears = require("gears")
wibox = require("wibox")
beautiful = require("beautiful")
naughty = require("naughty")
menubar = require("menubar")
-- switcher = require("switcher")

awful.rules = require("awful.rules")
require("awful.autofocus")

require("helpers")
require("menu")
require("keybindings")
require("toolbars")
require("wallpapers")
require("tags")
require("set")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.init(string.format("%s/.config/awesome/themes/default/theme.lua", os.getenv("HOME")))
-- beautiful.font = "Ubuntu Bold 8"
beautiful.notification_icon_size = 64

-- This is used later as the default terminal and editor to run.
terminal = "kitty"
-- terminal = "qterminal"
editor = "mcedit"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(get_tags(), s, layouts[10])
end
-- }}}

-- {{{ Menu

mainmenu = make_menu(terminal)

-- mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

make_toolbars()
make_widgets()
bind_mouse(mainmenu)
-- make_switcher()
bind_keyboard(modkey, mainmenu, switcher)

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will ma  tch this rule.
    { rule = { },
      properties =
      {
        -- border_width = beautiful.border_width,
        -- border_color = beautiful.border_normal,
        focus = awful.client.focus.filter,
        raise = true,
        keys = clientkeys,
        buttons = clientbuttons,
        screen = awful.screen.preferred,
        placement = awful.placement.no_overlap+awful.placement.no_offscreen
      }
    },
    -- { rule = { class = "MPlayer" }, properties = { floating = true } },
    -- { rule = { class = "pinentry" },properties = { floating = true } },
    -- { rule = { class = "gimp" }         , properties = { floating = true } },
    -- { rule = { class = "Firefox" }      , properties = { tag = get_tag("Browsers"), switchtotag = true, floating = true } },
    {
        rule = { role = "browser" },
        properties =
        {
            tag = get_tag("Browsers"),
            switchtotag = true,
            floating = false,
            maximized_horizontal = false,
            maximized_vertical = false,
            maximized = false
        }
    },
    { rule = { class = "code" }         , properties = { tag = get_tag("Work")    , switchtotag = true, floating = true } },
    { rule = { class = "audacious" }    , properties = { tag = get_tag("Media")   , switchtotag = true, screen = 1 } },
    { rule = { class = "shutter" }      , properties = { tag = get_tag("Media")   , switchtotag = true, screen = 1 } },
    { rule = { class = "Pidgin", role = "buddy_list" },
    properties = {floating=true,
                  maximized_vertical=true, maximized_horizontal=false },
    callback = function (c)
        local cl_width = 250    -- width of buddy list window

        local scr_area = screen[c.screen].workarea
        local cl_strut = c:struts()

        -- scr_area is affected by this client's struts, so we have to adjust for that
        if c:isvisible() and cl_strut ~= nil and cl_strut.left > 0 then
            c:geometry({x=scr_area.x-cl_strut.left, y=scr_area.y, width=cl_strut.left})
        -- scr_area is unaffected, so we can use the naive coordinates
        else
            c:struts({left=cl_width, right=0})
            c:geometry({x=scr_area.x, y=scr_area.y, width=cl_width})
        end
    end }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    local unacceptable_classes = Set { "Audacious", "audacious" }
    if (titlebars_enabled and c.type == "normal") or
       ( not unacceptable_classes[c.class] and (c.type == "dialog" or c.role == "app") ) then
        -- print(c.class)
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}



awful.spawn("setxkbmap -layout 'us,ru' -variant ',winkeys,winkeys' -option grp:caps_toggle -option grp_led:scroll -option terminate:ctrl_alt_bksp -option compose:menu")
awful.spawn("numlockx on")

run_once("pasystray")
run_once("xcompmgr -n -F -f -c -D 3")

init_wallpapers()
