require("helpers")

local cpu_stat = { current={}, prev={} }
local cpu_stat_widgets = {}
local cpu_widget_tooltips = {}
local cpu_stat_mutex = false

function load_cpu_stat()
    for line in io.lines("/proc/stat") do
        if string.match(line, "cpu[0-9]") then
            set_cpu_stat(split(line, " "))
        end
    end
end

function set_cpu_stat(stats)
    -- print(stats[10])
    cpu_stat.current[stats[1]] = {
        user   = stats[2 ],
        nice   = stats[3 ],
        system = stats[4 ],
        idle   = stats[5 ],
        iowait = stats[6 ],
        irq    = stats[7 ],
        sirq   = stats[8 ],
        steal  = stats[9 ],
        guest  = stats[10]
    }
end

function update_cpu_stat()
    if cpu_stat_mutex then return end
    cpu_stat_mutex = true
    load_cpu_stat()
    if table.length(cpu_stat.current) == table.length(cpu_stat.prev) then
        for cpu = 0, cpu_count()-1 do
            cpu_name = 'cpu' .. cpu
            if cpu_stat_widgets[cpu_name] then
                cpu_stat_widgets[cpu_name].data_list = {
                    { 'user'   , cpu_stat.current[cpu_name].user   - cpu_stat.prev[cpu_name].user  },
                    { 'nice'   , cpu_stat.current[cpu_name].nice   - cpu_stat.prev[cpu_name].nice  },
                    { 'system' , cpu_stat.current[cpu_name].system - cpu_stat.prev[cpu_name].system},
                    { 'idle'   , cpu_stat.current[cpu_name].idle   - cpu_stat.prev[cpu_name].idle  },
                    { 'iowait' , cpu_stat.current[cpu_name].iowait - cpu_stat.prev[cpu_name].iowait},
                    { 'irq'    , cpu_stat.current[cpu_name].irq    - cpu_stat.prev[cpu_name].irq   },
                    { 'sirq'   , cpu_stat.current[cpu_name].sirq   - cpu_stat.prev[cpu_name].sirq  },
                    { 'steal'  , cpu_stat.current[cpu_name].steal  - cpu_stat.prev[cpu_name].steal },
                    { 'guest'  , cpu_stat.current[cpu_name].guest  - cpu_stat.prev[cpu_name].guest }
                }
                local text = cpu_name .. "\n"
                for k,v in pairs(cpu_stat_widgets[cpu_name].data_list) do
                    text = text .. string.format("%s: %d\n", v[1], v[2])
                end
                cpu_widget_tooltips[cpu_name].text = text
            end
        end
    end
    cpu_stat.prev = table.shallow_copy(cpu_stat.current)
    cpu_stat_mutex = false
end

function cpu_count()
    if table.length(cpu_stat.current) == table.length(cpu_stat.prev) then
        return table.length(cpu_stat.current)
    end
    return 0
end

function init_cpu_stat()
    update_cpu_stat()
    update_cpu_stat()
end

function get_cpu_meter_widget(cpu)
    cpu_name = 'cpu' .. cpu
    if not cpu_stat_widgets[cpu_name] then
        cpu_stat_widgets[cpu_name] = wibox.widget {
            -- cpu_stat_widgets[cpu_name] =  {
            data_list = {
                { 'user'  , 0 },
                { 'nice'  , 1 },
                { 'system', 2 },
                { 'idle'  , 3 },
                { 'iowait', 4 },
                { 'irq'   , 5 },
                { 'sirq'  , 6 },
                { 'steal' , 7 },
                { 'guest' , 8 }
            },
            colors = {
                '#FF51C8',
                '#8B90FF',
                '#FF507B',
                '#51FF56',
                '#BEBEBE',
                '#FF55D9',
                '#FFADEC',
                '#FFF355',
                '#FFB328'
            },
            border_width = 0,
            display_labels = false,
            forced_width  = 24,
            forced_height = 24,
            widget = wibox.widget.piechart
        }
        cpu_widget_tooltips[cpu_name] = awful.tooltip({
            objects = { cpu_stat_widgets[cpu_name] },
            text    = ""
            })
    end
    return cpu_stat_widgets[cpu_name]
end

-- -- get_cpu_meter_widget()
-- init_cpu_stat()
-- print('count', cpu_count())
-- for cpu = 0, cpu_count()-1 do
--     get_cpu_meter_widget(cpu)
-- end
-- -- for i=1,3 do
--     update_cpu_stat()
--     require("socket").sleep(1)
--     update_cpu_stat()
-- -- end

-- for cpu = 0, cpu_count()-1 do
--     print('metr', cpu, get_cpu_meter_widget(cpu).data_list.idle)
-- end
