function bind_mouse(mainmenu)
    -- {{{ Mouse bindings
    root.buttons(awful.util.table.join(
        awful.button({ }, 3, function () mainmenu:toggle() end),
        awful.button({ }, 4, awful.tag.viewnext),
        awful.button({ }, 5, awful.tag.viewprev)
    ))
    -- }}}
end

function get_cyclefocus()
    local cyclefocus = require('cyclefocus')
    cyclefocus.display_next_count = 5
    cyclefocus.display_prev_count = 5
    return cyclefocus
end

function bind_keyboard(modkey, mainmenu, switcher)
    local cyclefocus = get_cyclefocus()
    -- {{{ Key bindings
    globalkeys = awful.util.table.join(
        awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
        awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
        awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

        awful.key({ modkey,           }, "j",
            function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
            end),
        awful.key({ modkey,           }, "k",
            function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
            end),
        awful.key({ modkey,           }, "w", function () mainmenu:show() end),

        -- Layout manipulation
        awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
        awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
        awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
        awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
        awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
        awful.key({ modkey,           }, "Tab",
            function ()
                awful.client.focus.byidx(-1)
                if client.focus then
                    client.focus:raise()
                end
            end),

        awful.key({ modkey, "Shift"   }, "Tab",
            function ()
                awful.client.focus.byidx(1)
                if client.focus then
                    client.focus:raise()
                end
            end),

        awful.key({modkey, "Control" }, "Tab",
            function ()
                cyclefocus.cycle({modifier="Super_L"})
            end),

        -- Standard program
        awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
        awful.key({ modkey, "Control" }, "r", awesome.restart),
        awful.key({ modkey, "Shift"   }, "q", awesome.quit),

        awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
        awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
        awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
        awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
        awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
        awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
        awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
        awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

        awful.key({ modkey, "Control" }, "n", awful.client.restore),
        awful.key({ modkey }, "p", function() menubar.show() end)
    )

    clientkeys = awful.util.table.join(
        awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
        awful.key({ modkey, "Control" }, "f",
                                    function(c)
                                        if c.floating then
                                            c.floating = false
                                            c.fullscreen = false
                                        else
                                            c.floating = true
                                            local geo = screen[1].geometry
                                            geo.x2 = geo.x + geo.width
                                            geo.y2 = geo.y + geo.height
                                            for s in screen do
                                                local geo2 = s.geometry
                                                geo.x = math.min(geo.x, geo2.x)
                                                geo.y = math.min(geo.y, geo2.y)
                                                geo.x2 = math.max(geo.x2, geo2.x + geo2.width)
                                                geo.y2 = math.max(geo.y2, geo2.y + geo2.height)
                                            end
                                            c:geometry{
                                                x = geo.x,
                                                y = geo.y,
                                                width = geo.x2 - geo.x,
                                                height = geo.y2 - geo.y
                                            }
                                        end
                                    end),
        awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
        awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
        awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
        awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end),
        awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
        awful.key({ modkey,           }, "n",
            function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
            end),
        awful.key({ modkey,           }, "m",
            function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c.maximized_vertical   = not c.maximized_vertical
            end)
    )

    -- Bind all key numbers to tags.
    -- Be careful: we use keycodes to make it works on any keyboard layout.
    -- This should map on the top row of your keyboard, usually 1 to 9.
    for i = 1, 9 do
        globalkeys = awful.util.table.join(globalkeys,
            -- View tag only.
            awful.key({ modkey }, "#" .. i + 9,
                    function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                            tag:view_only()
                        end
                    end),
            -- Toggle tag.
            awful.key({ modkey, "Control" }, "#" .. i + 9,
                    function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                            awful.tag.viewtoggle(tag)
                        end
                    end),
            -- Move client to tag.
            awful.key({ modkey, "Shift" }, "#" .. i + 9,
                    function ()
                        if client.focus then
                            local tag = client.focus.screen.tags[i]
                            if tag then
                                client.focus:move_to_tag(tag)
                            end
                        end
                    end),
            -- Toggle tag on focused client.
            awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                    function ()
                        if client.focus then
                            local tag = client.focus.screen.tags[i]
                            if tag then
                                client.focus:toggle_tag(tag)
                            end
                        end
                    end))
    end

    clientbuttons = awful.util.table.join(
        awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
        awful.button({ modkey }, 1, awful.mouse.client.move),
        awful.button({ modkey }, 3, awful.mouse.client.resize))

    -- Set keys
    root.keys(globalkeys)
    -- }}}
end
