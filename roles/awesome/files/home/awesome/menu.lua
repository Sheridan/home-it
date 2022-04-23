local freedesktop = require("freedesktop")

function make_menu(terminal)
    hand_menu =
    {
        { "Usefull",
            {
                { "Chrome"               , "google-chrome-stable --no-proxy-server" },
                { "VSCode"               , "vscode --new-window"},
                { "Telegram"             , "telegram-desktop"},
                { "Discord"              , "discord"},
                { "Element"              , "element-desktop"},
                { "Скриншотер"           , "flameshot"},
                { "Passwords"            , "keepassxc"},
                { "Калькулятор"          , "speedcrunch"}
            },
        }
    }

    awesome_menu =
    {
        { "Awesome",
            {
                { "restart"    , awesome.restart },
                { "quit"       , function() awesome.quit() end }
            }, beautiful.awesome_icon
        }
    }

    main_menu = freedesktop.menu.build({
        before = hand_menu,
        after  = awesome_menu
    })

    return main_menu
end
