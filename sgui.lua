local zlib = {}
local component = require "component"
local unicode = require "unicode"
local gpu = component.gpu

-- Проверка доступности интерфейса ME
if component.isAvailable("me_interface") then
    me = component.me_interface
end

local version = "[v0.2]"
local author = "[Zayats & Stawlie]"

-- Функция для рисования прогрессбара
function zlib.bar(x, y, fill, w, color, type)
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

-- Функция для рисования кнопки
function zlib.button(x, y, bcolor, tcolor, text)
    local oldColors = {gpu.getForeground(), gpu.getBackground()}
    gpu.setForeground(bcolor)
    local h = 2
    local w = 3 + unicode.len(text)
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

-- Функция для изменения разрешения экрана
function zlib.resolution(w, h)
    w = w or 45
    h = h or 15
    gpu.setResolution(w, h)
end 

-- Функция для рисования рамки
function zlib.main(color, w, h, text, offset)
    offset = offset or 0
    zlib.resolution(w, h)
    local oldColors = {gpu.getForeground(), gpu.getBackground()}
    gpu.setForeground(color)
    gpu.set(1, 1, "╔")
    gpu.set(1, h, "╚")
    gpu.set(w, 1, "╗")
    gpu.set(w, h, "╝")
    gpu.fill(2, 1, w - 2, 1, "═")
    gpu.fill(2, h, w - 2, 1, "═")
    gpu.fill(1, 2, 1, h - 2, "║")
    gpu.fill(w, 2, 1, h - 2, "║")
    local textX = w / 2 - (unicode.len(text) / 2) - 2
    gpu.set(textX, 1, "["..text.."]")
    gpu.set(textX, h, author)
    gpu.set(w - 5 - string.len(version), h, version)
    gpu.setBackground(oldColors[2])
    gpu.setForeground(oldColors[1]) 
end

-- Функция для рисования символов (цифры)
function zlib.symb(x, y, s, color)
    -- Сохраняем текущие цвета перед изменением
    local oldColors = {gpu.getForeground(), gpu.getBackground()}
    -- Устанавливаем передний план (цвет текста) для символа
    gpu.setForeground(color)
    
    -- Определение символов для каждой цифры
    local symbols = {
        [1] = {
            " ███╗   ",
            " ████║  ",
            "██╔██║  ",
            "╚═╝██║  ",
            "███████╗",
            "╚══════╝",
        },
        [2] = {
            "██████╗ ",
            "╚════██╗",
            "  ███╔═╝",
            "██╔══╝  ",
            "███████╗",
            "╚══════╝",
        },
        [3] = {
            "██████╗ ",
            "╚════██╗",
            " █████╔╝",
            " ╚═══██╗",
            "██████╔╝",
            "╚══════╝",
        },
        [4] = {
            "  ██╗██╗",
            " ██╔╝██║",
            "██╔╝ ██║",
            "███████║",
            "╚════██║",
            "     ╚═╝",
        },
        [5] = {
            "███████╗",
            "██╔════╝",
            "██████╗ ",
            "╚════██╗",
            "██████╔╝",
            "╚═════╝ ",
        },
        [6] = {
            " █████╗ ",
            "██╔═══╝ ",
            "██████╗ ",
            "██╔══██╗",
            "╚█████╔╝",
            " ╚════╝ ",
        },
        [7] = {
            "███████╗",
            "╚════██║",
            "    ██╔╝",
            "   ██╔╝ ",
            "  ██╔╝  ",
            "  ╚═╝   ",
        },
        [8] = {
            " █████╗ ",
            "██╔══██╗",
            "╚█████╔╝",
            "██╔══██╗",
            "╚█████╔╝",
            " ╚════╝ ",
        },
        [9] = {
            " █████╗ ",
            "██╔══██╗",
            "╚██████║",
            " ╚═══██║",
            " █████╔╝",
            " ╚════╝ ",
        },
        [0] = {
            " █████╗ ",
            "██╔══██╗",
            "██║  ██║",
            "██║  ██║",
            " █████╔╝",
            " ╚════╝ ",
        },
    }
    
    -- Рисуем символ на экране
    local symbol = symbols[s]
    for i, line in ipairs(symbol) do
        gpu.set(x, y + i - 1, line)
    end
    
    -- Восстанавливаем исходные цвета
    gpu.setBackground(oldColors[2])
    gpu.setForeground(oldColors[1])   
end

-- Возвращаем таблицу с функциями
return zlib

-- Функция для установки цвета текста
function zlib.setColor(index)
    local back
    if index ~= "r" then
        back = gpu.getForeground()
    end
    local colors = {
        ["0"] = 0x333333,
        ["1"] = 0x0000ff,
        ["2"] = 0x00ff00,
        ["3"] = 0x24b3a7,
        ["4"] = 0xff0000,
        ["5"] = 0x8b00ff,
        -- Остальные цвета
    }
    if colors[index] then
        gpu.setForeground(colors[index])
    end
    if index == "r" then
        gpu.setForeground(back)
    end
end

-- Функция для вывода текста с поддержкой цвета
function zlib.text(x, y, text)
    local n = 1
    for i = 1, unicode.len(text) do
        if unicode.sub(text, i, i) == "&" then
            zlib.setColor(unicode.sub(text, i + 1, i + 1))
        elseif unicode.sub(text, i - 1, i - 1) ~= "&" then
            gpu.set(x + n, y, unicode.sub(text, i, i))
            n = n + 1
        end
    end 
end

-- Функции для вывода текста в определенных позициях
function zlib.midL(w, y, text, color)
    local _, n = string.gsub(text, "&", "")
    local l = unicode.len(text) - n * 2
    local x = 13 - (l / 2)
    zlib.text(x + 2, y, text)
end

function zlib.midR(w, y, text, color)
    local _, n = string.gsub(text, "&", "")
    local l = unicode.len(text) - n * 2
    local x = ((w - 34) / 2) - (l / 2)
    zlib.text(x + 31, y, text)
end

function zlib.mid(w, y, text, color)
    local _, n = string.gsub(text, "&", "")
    local l = unicode.len(text) - n * 2
    local x = (w / 2) - (l / 2)
    zlib.text(x, y, text)
end

-- Функция для получения размера предмета в ME-сети
function zlib.itemSize(name, dmg)
    for _, i in pairs(me.getAvailableItems()) do 
        if i.fingerprint.id == name and i.fingerprint.dmg == dmg then 
            return i.size
        end
    end
    return 0
end

-- Функция для рисования прямоугольника
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