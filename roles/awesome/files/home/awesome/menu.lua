local freedesktop = require("freedesktop")

function make_menu(terminal)
    hand_menu =
    {
        { "Usefull",
            {
                { "Chrome"               , "google-chrome-stable --no-proxy-server" },
                -- { "Chrome tor"           , "google-chrome-stable --proxy-server='socks5://10.100.100.1:9050'" },
                { "Skype"                , "skypeforlinux" },
                { "Telegram"             , "telegram-desktop"},
                { "VSCode"               , "visual-studio-code --new-window"},
                { "Скриншотер"           , "flameshot"},
                { "File manager"         , "qtfm"},
                { "Passwords"            , "keepassxc"},
                { "Калькулятор"          , "speedcrunch"}
            },
        },
        { "Рабочее",
            {
                { "GitInSky Chrome"      , "google-chrome-stable --user-data-dir = /home/sheridan/.gitinsky/google-chrome" }
            },
        },
        { "My",
            {
                { "Cam", "ffplay -loglevel panic rtsp://viewer:viewer@91.210.98.62/h264Preview_01_main" }
            },
        },
        { "Awesome",
            {
                { "manual"     , terminal .. " -e man awesome" },
                { "edit config", "visual-studio-code -n /home/sheridan/.config/awesome" },
                { "restart"    , awesome.restart },
                { "quit"       , function() awesome.quit() end }
            }, beautiful.awesome_icon
        }
    }

    main_menu = freedesktop.menu.build({
        before = hand_menu
    })

    return main_menu
end
