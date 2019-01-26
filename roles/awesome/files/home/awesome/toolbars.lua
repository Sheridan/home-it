local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local toolbar_layouts = {}
local sensorbar_layout = 0

function make_sensorbar(to_screen, to_position)
    bar = awful.wibar({
        position = to_position,
        screen = to_screen,
        width = dpi(128),
        border_width = dpi(0)
    })
    local top_layout = wibox.layout.fixed.vertical()
    sensorbar_layout = top_layout
    bar:set_widget(top_layout)
end

function make_toolbars()
    for s = 1, screen.count() do
        bar = awful.wibar({
            position = "top",
            screen = s,
            height = dpi(24),
            border_width = dpi(0)
        })
        local left_layout = wibox.layout.fixed.horizontal()
        local right_layout = wibox.layout.fixed.horizontal()
        local middle_layout = wibox.layout.align.horizontal()
        middle_layout:set_left(left_layout)
        middle_layout:set_right(right_layout)
        set_toolbar(s, left_layout, middle_layout, right_layout)
        bar:set_widget(middle_layout)
        -- print(s)
    end
end

function set_toolbar(screen, left_layout, middle_layout, right_layout)
    toolbar_layouts[screen] = {left=left_layout, middle=middle_layout, right=right_layout}
end

function add_widget_to_toolbar(screen, side, widget)
    toolbar_layouts[screen][side]:add(widget)
end

function make_taglist_widgets()
    local taglist = {}
    taglist.buttons = awful.util.table.join(
        awful.button({ }, 1, function(t) t:view_only() end),
        awful.button({ modkey }, 1, function(t)
                                        if client.focus then
                                            client.focus:move_to_tag(t)
                                        end
                                    end),
        awful.button({ }, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, function(t)
                                        if client.focus then
                                            client.focus:toggle_tag(t)
                                        end
                                    end),
        awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
        awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
    )
    for s = 1, screen.count() do
        w = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist.buttons)
        w.font = "Ubuntu 8"
        add_widget_to_toolbar(s, "left", w)
    end
end

function context_menu(c)
    cli_min = "Minimized"
    if c.minimized then
        cli_min = "★ " .. cli_min
    end
    cli_top = "On top"
    if c.ontop then
        cli_top = "★ " .. cli_top
    end
    cli_float = "Floating"
    if awful.client.floating.get(c) then
        cli_float = "★ " .. cli_float
    end
    menu_items = {
            { cli_min     , function() c.minimized = not c.minimized end   , beautiful.titlebar_minimize_button_focus},
            { "Fullscreen", function() c.fullscreen = not c.fullscreen end , beautiful.layout_fullscreen },
            { cli_float   , function() awful.client.floating.toggle(c) end, beautiful.titlebar_floating_button_focus_active },
            { cli_top     , function() c.ontop = not c.ontop end           , beautiful.titlebar_ontop_button_focus_active },
            { "Close"     , function() c:kill() end                        , beautiful.titlebar_close_button_focus}
        }
    taskmenu = awful.menu(menu_items)
    taskmenu:show()
    return taskmenu
end

function make_tasklist_widgets()
    local tasklist = {}
    tasklist.buttons = awful.util.table.join(
        awful.button({ }, 1,
            function (c)
                if c == client.focus then
                    c.minimized = true
                else
                    -- Without this, the following
                    -- :isvisible() makes no sense
                    c.minimized = false
                    if not c:isvisible() and c.first_tag then
                        -- awful.tag.viewonly(c:tags()[1])
                        c.first_tag:view_only()
                    end
                    -- This will also un-minimize
                    -- the client, if needed
                    client.focus = c
                    c:raise()
                end
            end
        ),
        awful.button({ }, 3,
            function (c)
                if instance then
                    instance:hide()
                    instance = nil
                else
                    instance = context_menu(c)
                end
            end
        ),
        awful.button({ }, 4,
            function ()
                awful.client.focus.byidx(1)
                if client.focus then client.focus:raise() end
            end
        ),
        awful.button({ }, 5,
            function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
            end
        )
    )
    for s = 1, screen.count() do
        toolbar_layouts[s].middle:set_middle(awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist.buttons))
    end
end

function make_layout_widgets()
    for s = 1, screen.count() do
        local layoutbox = awful.widget.layoutbox(s)
        layoutbox:buttons(
            awful.util.table.join(
                awful.button({ }, 1, function () awful.layout.inc(layouts,  1) end),
                awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                awful.button({ }, 4, function () awful.layout.inc(layouts,  1) end),
                awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)
            )
        )
        add_widget_to_toolbar(s, "right", layoutbox)
    end
end

function make_clock()
    local textclock = wibox.widget.textclock("%A, %Y.%m.%d %H:%M:%S", 1)
    add_widget_to_toolbar(screen_layout.left, "right", textclock)
end

function make_widgets()
    add_widget_to_toolbar(screen_layout.left, "left", awful.widget.launcher({ image = beautiful.awesome_icon, menu = mainmenu }))
    make_taglist_widgets()
    make_tasklist_widgets()
    make_clock()
    add_widget_to_toolbar(screen_layout.right , "right", awful.widget.keyboardlayout())
    add_widget_to_toolbar(screen_layout.center, "right", wibox.widget.systray())
    make_layout_widgets()
end
