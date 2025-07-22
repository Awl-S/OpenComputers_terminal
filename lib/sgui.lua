-- Author: https://github.com/Awl-S

ugui = {}
local gpu = require("component").gpu
local unicode = require("unicode")

ugui.colors = {
    ["0"] = 0x333333,
    ["1"] = 0x0000ff,
    ["2"] = 0x00ff00,
    ["3"] = 0x24b3a7,
    ["4"] = 0xff0000,
    ["5"] = 0x8b00ff,
    ["6"] = 0xffa500,
    ["7"] = 0xbbbbbb,
    ["8"] = 0x808080,
    ["9"] = 0x0000ff,
    ["a"] = 0x66ff66,
    ["b"] = 0x00ffff,
    ["c"] = 0xff6347,
    ["d"] = 0xff00ff,
    ["e"] = 0xffff00,
    ["f"] = 0xffffff,
    ["g"] = 0x00ff00,
    ["border"] = 0x525FE1,
}

function ugui.setColor(index)
    local back = gpu.getForeground()
    local newColor = ugui.colors[index]
    if newColor then
        gpu.setForeground(newColor)
    elseif index == "r" then
        gpu.setForeground(back)
    end
end

function ugui.text(x, y, text)
    local n = 0
    local isColorCode = false

    for i = 1, unicode.len(text) do
        local char = unicode.sub(text, i, i)

        if char == "&" then
            isColorCode = true
        elseif isColorCode then
            isColorCode = false
            if ugui.colors[char] then
                ugui.setColor(char)
            end
        else
            n = n + 1
            gpu.set(x + n, y, char)
        end
    end
end

function ugui.drawCube(x, y, width, height, color)
    local topBorder = "╭" .. string.rep("⎯", width - 2) .. "╮"
    local middleRow = "│" .. string.rep(" ", width - 2) .. "│"
    local bottomBorder = "╰" .. string.rep("⎯", width - 2) .. "╯" -- ━
    gpu.setForeground(color)
    gpu.set(x, y, topBorder)     -- Draw top border
    for i = 1, height - 2 do
        gpu.set(x, y + i, middleRow)     -- Draw middle rows
    end
    gpu.set(x, y + height - 1, bottomBorder)     -- Draw bottom border
end

function ugui.drawMain(nameTable, color, version)
    local width, height = gpu.getResolution()
    ugui.drawCube(1, 1, width, height, color)  
    ugui.text(math.floor((width/2)-unicode.len(nameTable)/2), 1,  nameTable)
    ugui.text(5, height, "&9[&bAuthor: Stawlie_&9] &bgithub.com/Awl-S/Monitoring-Ala ")
    vers = "&b[v" .. version .. "]"
    ugui.text(width-#vers-5, height, vers)
end

function ugui.drawFrame(x, y, width, height, nameTitle, color)
    ugui.drawCube(x, y, width, height, color)
    ugui.text(x+1, y, "[" ..nameTitle .. "]")
end

return ugui