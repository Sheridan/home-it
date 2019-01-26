local taglist = {
    { icon = "💾", name="Work"     },
    { icon = "🏠", name="Home"     },
    { icon = "🎵", name="Media"    },
    { icon = "🌐", name="Browsers" },
    { icon = "⏳", name="Other"    }
}

function decorate(e)
    return " " .. e .. " "
end

function get_tags()
    result={}
    for i,e in pairs(taglist) do
        table.insert(result, decorate(e.icon))
    end
    return result
end

function get_tag(name)
    for i,e in pairs(taglist) do
        if e.name == name then
            return decorate(e.icon)
        end
    end
    return nil
end
