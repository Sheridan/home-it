local freedesktop = require("freedesktop")

function make_menu(terminal)
    hand_menu =
    {
        { "Usefull",
            {
                { "Chrome"               , "google-chrome-stable --no-proxy-server" },
                { "Skype"                , "skypeforlinux" },
                { "Telegram"             , "telegram-desktop"},
                { "VSCode"               , "visual-studio-code --new-window"},
                { "Скриншотер"           , "flameshot gui"},
                { "File manager"         , "qtfm"},
                { "Passwords"            , "keepassxc"},
                { "Калькулятор"          , "speedcrunch"}
            },
        },
        { "My",
            {
                { "Cam", "ffplay -loglevel panic rtsp://viewer:viewer@ip-camera-garage.sheridan-home.local/h264Preview_01_main" }
            },
        },
        { "Awesome",
            {
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
