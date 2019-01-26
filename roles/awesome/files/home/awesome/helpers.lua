function run_once(prg)
  if not prg then
      do return nil end
  end
  awful.util.spawn_with_shell("x=" .. prg .. "; pgrep -u $USERNAME -x " .. prg .. " || (" .. prg .. ")")
end

function split(str, sep)
    fields = {}
    str:gsub("([^"..sep.."]*)"..sep, function(c)
        table.insert(fields, c)
    end)
    return fields
end

function dump(o)
  if type(o) == 'table' then
     local s = '{\n'
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '\t['..k..'] = ' .. dump(v) .. ',\n'
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

function table.length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end
