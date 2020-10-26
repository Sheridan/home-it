local freedesktop = require("freedesktop")

function make_menu(terminal)
    hand_menu =
    {
        { "Usefull",
            {
                { "Chrome"               , "google-chrome-stable --no-proxy-server" },
                { "Skype"                , "skypeforlinux" },
                { "Telegram"             , "telegram-desktop"},
                { "VSCode"               , "vscode --new-window"},
                { "Скриншотер"           , "flameshot"},
                { "File manager"         , "qtfm"},
                { "Passwords"            , "keepassxc"},
                { "Калькулятор"          , "speedcrunch"}
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
