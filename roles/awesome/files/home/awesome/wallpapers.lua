function set_wallpaper()
    for s = 1, screen.count() do
        local f = io.popen("sh -c \"find ~/wallpapers/ -type f -name '*.*' | shuf -n 1 | xargs echo -n\"")
        local wallpaper = f:read("*all")
        f:close()
        gears.wallpaper.maximized(wallpaper, s, false)
    end
end

function init_wallpapers()
    set_wallpaper()
    gears.timer {
        timeout   = 300,
        autostart = true,
        callback  = set_wallpaper
    }
    screen.connect_signal("property::geometry", set_wallpaper)
end
