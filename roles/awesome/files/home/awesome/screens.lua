function get_screen_index(name)
    if screen_layout[name] then
      return screen_layout[name]
    end
    return default_screen_index
end
