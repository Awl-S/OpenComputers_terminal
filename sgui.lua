local zlib = {}
local component = require "component"
local unicode = require "unicode"
local gpu = component.gpu

if component.isAvailable("me_interface") then
    me = component.me_interface
end

local version = "[v0.2]"
local author = "[Zayats & Stawlie]"

function zlib.bar(x, y, fill, w, color, type) -- прогрессбар
    local oldColors = {gpu.getForeground(), gpu.getBackground()}
    gpu.setBackground(0xF0F0F0)
    gpu.fill(x, y - 1, 1, w, "▄")
    gpu.fill(x, y + 1, 1, w, "▄")
    gpu.setBackground(color)
    if type == "y" then
        gpu.fill(x, y, w, fill, "▄")
    else
        gpu.fill(x, y, fill, w, "▄")
    end 
    gpu.setBackground(oldColors[2])
    gpu.setForeground(oldColors[1])
end 

function zlib.button(x, y, bcolor, tcolor, text) --кнопочка
    local oldColors = {gpu.getForeground(), gpu.getBackground()}
    gpu.setForeground(bcolor)
    h = 2
    w = 3 + unicode.len(text)
    gpu.set(x, y, "╔")
    gpu.set(x, y + h, "╚")
    gpu.set(x + w, y, "╗")
    gpu.set(x + w, y + h, "╝")
    gpu.fill(x + 1, y, w - 1, 1, "═")
    gpu.fill(x + 1, y + h, w - 1, 1, "═")
    gpu.fill(x, y + 1, 1, h - 1, "║")
    gpu.fill(x + w, y + 1, 1, h - 1, "║")
    gpu.setForeground(tcolor)
    gpu.set(x + 2, y + 1, text)
    gpu.setBackground(oldColors[2])
    gpu.setForeground(oldColors[1])
end

function zlib.resolution(w, h)
    local w = w or 45
    local h = h or 15
    gpu.setResolution(w, h)
end 

function zlib.main(color, w, h, text, offset) -- рамка 
    offset = offset or 0
    zlib.resolution(w, h)
    local oldColors = {gpu.getForeground(), gpu.getBackground()}
    gpu.setForeground(color)
    gpu.set(1, 1, "╔")
    gpu.set(1, h, "╚")
    gpu.set(w, 1, "╗")
    gpu.set(w , h, "╝")
    gpu.fill(2, 1, w - 2, 1, "═")
    gpu.fill(2, h, w - 2, 1, "═")
    gpu.fill(1, 2, 1, h - 2, "║")
    gpu.fill(w, 2, 1, h - 2, "║")
    gpu.set(w / 2 - (unicode.len(text) / 2) - 2, 1, "["..text.."]")
    gpu.set(w / 2 - (unicode.len(text) / 2)-2, h, author)
    gpu.set(w - 5 - string.len(version), h, version)
    gpu.setBackground(oldColors[2])
    gpu.setForeground(oldColors[1]) 
end
function zlib.symb(x, y, s, color) -- цыфферки
    local oldColors = {gpu.getForeground(), gpu.getBackground()}
    gpu.setForeground(color)
    if s == 1 then
            gpu.set(x, y,     " ███╗   ")
            gpu.set(x, y + 1, " ████║  ")
            gpu.set(x, y + 2, "██╔██║  ")
            gpu.set(x, y + 3, "╚═╝██║  ")
            gpu.set(x, y + 4, "███████╗")
            gpu.set(x, y + 5, "╚══════╝")
        elseif s == 2 then
            gpu.set(x, y,     "██████╗ ")
            gpu.set(x, y + 1, "╚════██╗")
            gpu.set(x, y + 2, "  ███╔═╝")
            gpu.set(x, y + 3, "██╔══╝  ")
            gpu.set(x, y + 4, "███████╗")
            gpu.set(x, y + 5, "╚══════╝")
        elseif s == 3 then
            gpu.set(x, y,     "██████╗ ")
            gpu.set(x, y + 1, "╚════██╗")
            gpu.set(x, y + 2, " █████╔╝")
            gpu.set(x, y + 3, " ╚═══██╗")
            gpu.set(x, y + 4, "██████╔╝")
            gpu.set(x, y + 5, "╚══════╝")
        elseif s == 4 then
            gpu.set(x, y,     "  ██╗██╗")
            gpu.set(x, y + 1, " ██╔╝██║")
            gpu.set(x, y + 2, "██╔╝ ██║")
            gpu.set(x, y + 3, "███████║")
            gpu.set(x, y + 4, "╚════██║")
            gpu.set(x, y + 5, "     ╚═╝")
        elseif s == 5 then
            gpu.set(x, y,     "███████╗")
            gpu.set(x, y + 1, "██╔════╝")
            gpu.set(x, y + 2, "██████╗ ")
            gpu.set(x, y + 3, "╚════██╗")
            gpu.set(x, y + 4, "██████╔╝")
            gpu.set(x, y + 5, "╚═════╝ ")
        elseif s == 6 then
            gpu.set(x, y,     " █████╗ ")
            gpu.set(x, y + 1, "██╔═══╝ ")
            gpu.set(x, y + 2, "██████╗ ")
            gpu.set(x, y + 3, "██╔══██╗")
            gpu.set(x, y + 4, "╚█████╔╝")
            gpu.set(x, y + 5, " ╚════╝ ")
        elseif s == 7 then
            gpu.set(x, y,     "███████╗")
            gpu.set(x, y + 1, "╚════██║")
            gpu.set(x, y + 2, "    ██╔╝")
            gpu.set(x, y + 3, "   ██╔╝ ")
            gpu.set(x, y + 4, "  ██╔╝  ")
            gpu.set(x, y + 5, "  ╚═╝   ")
        elseif s == 8 then
            gpu.set(x, y,     " █████╗ ")
            gpu.set(x, y + 1, "██╔══██╗")
            gpu.set(x, y + 2, "╚█████╔╝")
            gpu.set(x, y + 3, "██╔══██╗")
            gpu.set(x, y + 4, "╚█████╔╝")
            gpu.set(x, y + 5, " ╚════╝ ")
        elseif s == 9 then
            gpu.set(x, y,     " █████╗ ")
            gpu.set(x, y + 1, "██╔══██╗")
            gpu.set(x, y + 2, "╚██████║")
            gpu.set(x, y + 3, " ╚═══██║")
            gpu.set(x, y + 4, " █████╔╝")
            gpu.set(x, y + 5, " ╚════╝ ")
        elseif s == 0 then
            gpu.set(x, y,     " █████╗ ")
            gpu.set(x, y + 1, "██╔══██╗")
            gpu.set(x, y + 2, "██║  ██║")
            gpu.set(x, y + 3, "██║  ██║")
            gpu.set(x, y + 4, " █████╔╝")
            gpu.set(x, y + 5, " ╚════╝ ")
    end
    gpu.setBackground(oldColors[2])
    gpu.setForeground(oldColors[1])   
end
function zlib.setColor(index) --Список цветов
  if (index ~= "r") then back = gpu.getForeground()  end
  if (index == "0") then gpu.setForeground(0x333333) end
  if (index == "1") then gpu.setForeground(0x0000ff) end
  if (index == "2") then gpu.setForeground(0x00ff00) end
  if (index == "3") then gpu.setForeground(0x24b3a7) end
  if (index == "4") then gpu.setForeground(0xff0000) end
  if (index == "5") then gpu.setForeground(0x8b00ff) end
  if (index == "6") then gpu.setForeground(0xffa500) end
  if (index == "7") then gpu.setForeground(0xbbbbbb) end
  if (index == "8") then gpu.setForeground(0x808080) end
  if (index == "9") then gpu.setForeground(0x0000ff) end
  if (index == "a") then gpu.setForeground(0x66ff66) end
  if (index == "b") then gpu.setForeground(0x00ffff) end
  if (index == "c") then gpu.setForeground(0xff6347) end
  if (index == "d") then gpu.setForeground(0xff00ff) end
  if (index == "e") then gpu.setForeground(0xffff00) end
  if (index == "f") then gpu.setForeground(0xffffff) end
  if (index == "g") then gpu.setForeground(0x00ff00) end
  if (index == "r") then gpu.setForeground(back)     end
end

function zlib.text(x, y, text)--text
  local n = 1
  for i = 1, unicode.len(text) do
    if unicode.sub(text, i,i) == "&" then
      zlib.setColor(unicode.sub(text, i + 1, i + 1))
    elseif unicode.sub(text, i - 1, i - 1) ~= "&" then
      gpu.set(x+n,y, unicode.sub(text, i,i))
      n = n + 1
    end
  end 
end

function zlib.midL(w, y, text, color)--left text
    local _,n = string.gsub(text, "&","")
  local l = unicode.len(text) - n * 2
    x = 13 - (l / 2)
  zlib.text(x+2, y, text)
end
function zlib.midR(w, y, text, color)--right text
    local _,n = string.gsub(text, "&","")
  local l = unicode.len(text) - n * 2
    x = ((w - 34) / 2) - (l / 2)
  zlib.text(x+31, y, text)
end
function zlib.mid(w, y, text, color)--middle text
    local _,n = string.gsub(text, "&","")
  local l = unicode.len(text) - n * 2
    x = (w / 2) - (l / 2)
  zlib.text(x, y, text)
end
function zlib.itemSize(name, dmg)--item size in me network
    for _, i in pairs(me.getAvailableItems()) do 
        if i.fingerprint.id == name and i.fingerprint.dmg == dmg then 
            return i.size
        end
    end
    return 0
end
function zlib.cube(x, y, w, h, color)
    gpu.setForeground(color)
    gpu.set(x, y, "╔")
    gpu.set(x, y + h, "╚")
    gpu.set(x + w, y, "╗")
    gpu.set(x + w, y + h, "╝")
    gpu.fill(x + 1, y, w - 1, 1, "═")
    gpu.fill(x + 1, y + h, w - 1, 1, "═")
    gpu.fill(x, y + 1, 1, h - 1, "║")
    gpu.fill(x + w, y + 1, 1, h - 1, "║")
end
return zlib