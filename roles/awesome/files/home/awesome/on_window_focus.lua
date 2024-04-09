polychromatic_folder= os.getenv("HOME") .. "/.config/polychromatic/effects/"
default_enabled=false

function on_window_focus(client)
  filename = string.gsub(client.instance, "[^%w]", "")
  conf_filename = polychromatic_folder .. filename .. ".json"
  gears.debug.print_warning(conf_filename)
  if gears.filesystem.file_readable(conf_filename) then
    awful.spawn("polychromatic-cli --effect " .. client.instance)
    default_enabled = false
  else
    if not default_enabled then
      awful.spawn("polychromatic-cli --option reactive -p 4 -c 00ffaa")
      default_enabled = true
    end
  end
end
