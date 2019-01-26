require("helpers")
local memory_stat_widgets = { }
local memory_widget_tooltips = { }

function load_memory_stat()
    local meminfo = {}
    for line in io.lines("/proc/meminfo") do
        if string.match(line, "^MemTotal:")     then meminfo.total     = split(line, " *")[2] end
        if string.match(line, "^MemFree:")      then meminfo.free      = split(line, " *")[2] end
        -- if string.match(line, "^MemAvailable:") then meminfo.available = split(line, " *")[2] end
        if string.match(line, "^Buffers:")      then meminfo.buffers   = split(line, " *")[2] end
        if string.match(line, "^Cached:")       then meminfo.cached    = split(line, " *")[2] end
        if string.match(line, "^SwapCached:")   then meminfo.scached   = split(line, " *")[2] end
        if string.match(line, "^SwapTotal:")    then meminfo.stotal    = split(line, " *")[2] end
        if string.match(line, "^SwapFree:")     then meminfo.sfree     = split(line, " *")[2] end
    end
--    print(dump(meminfo))
    return meminfo
end

function update_memory_stat()
    local meminfo = load_memory_stat()
    memory_stat_widgets.memory.data_list = {
        { 'used'     , meminfo.total - meminfo.free - meminfo.buffers - meminfo.cached - meminfo.scached },
        { 'free'     , meminfo.free },
        { 'buffers'  , meminfo.buffers },
        { 'cached'   , meminfo.cached },
        { 'scached'  , meminfo.scached }
    }
    memory_widget_tooltips.memory.text = make_tooltip_text('memory', memory_stat_widgets.memory.data_list)
    memory_stat_widgets.swap.data_list = {
        { 'used'     , meminfo.stotal - meminfo.sfree },
        { 'free'     , meminfo.sfree },
        { 'cached'   , meminfo.scached }
    }
    memory_widget_tooltips.swap.text = make_tooltip_text('swap', memory_stat_widgets.swap.data_list)
end

function make_tooltip_text(wtype, data)
    local text = wtype .. "\n"
    for k,v in pairs(data) do
        text = text .. string.format("%s: %d\n", v[1], v[2])
    end
    return text
end

function get_memory_meter_widget(wtype)
    if not memory_stat_widgets[wtype] then
        if wtype == 'memory' then
            memory_stat_widgets[wtype] = wibox.widget {
                data_list = {
                    { 'used'     , 0 },
                    { 'free'     , 1 },
                    { 'buffers'  , 2 },
                    { 'cached'   , 3 },
                    { 'scached'  , 4 }
                },
                colors = {
                    '#FF5E5C',
                    '#64FF5C',
                    '#FFB45C',
                    '#FEFFA0',
                    '#FFA0F9'
                },
                border_width = 0,
                display_labels = false,
                forced_width  = 24,
                forced_height = 24,
                widget = wibox.widget.piechart
            }
        end
        if wtype == 'swap' then
            memory_stat_widgets[wtype] = wibox.widget {
                data_list = {
                    { 'used'  , 0 },
                    { 'free'  , 1 },
                    { 'cached', 2 }
                },
                colors = {
                    '#FF6459',
                    '#5CFF59',
                    '#ECC74D',
                },
                border_width = 0,
                display_labels = false,
                forced_width  = 24,
                forced_height = 24,
                widget = wibox.widget.piechart
            }
        end
        memory_widget_tooltips[wtype] = awful.tooltip({
            objects = { memory_stat_widgets[wtype] },
            text    = ""
            })
    end
    return memory_stat_widgets[wtype]
end

--load_memory_stat()
