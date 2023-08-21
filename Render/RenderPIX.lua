local shell = require("shell")
local computer = require("computer")
local component = require("component")
local unicode = require("unicode")
local term = require("term")
local gpu = component.gpu
local args = shell.parse(...)
local symbols = {"▄", "▀", "█", " "}

local function bytesToInt(str)
  local integer = 0
  for i = 1, #str do
    integer = (integer << 8) + string.byte(str, i)
  end
  return integer
end

local function bytesToSymbolString(str, len)
  local out = ""
  local temp
  for i = 1, #str do
    temp = str:byte(i)
    for j = 6, 0, -2 do
      out = out .. symbols[(temp >> j) + 1]
      temp = temp % (2 ^ j)
    end
  end
  return out
end

local function readFromFile(path)
  local file = io.open(path, "rb")
  local data = file:read("*a")
  file:close()
  local index = 1

  local function readBytes(n)
    index = index + n
    return string.sub(data, index - n, index - 1)
  end

  --[[ Background Color, Foreground Color, Width, Height ]]

  local backgroundForeground = {bytesToInt(readBytes(1)), bytesToInt(readBytes(1)), bytesToInt(readBytes(3)), bytesToInt(readBytes(3))}

  --[[ Color Mapping ]]

  local lenStr = bytesToInt(readBytes(2))
  local colorString = bytesToSymbolString(readBytes(math.ceil(lenStr / 4)), lenStr)

  local function getString(n)
    local temp = unicode.sub(colorString, 1, n)
    colorString = unicode.sub(colorString, n + 1)
    return temp
  end

  local lenColorMapping = bytesToInt(readBytes(2))
  local colorMapping = {}

  for i = 1, lenColorMapping do
    local foreground = bytesToInt(readBytes(3))
    local lenColorMappingForeground = bytesToInt(readBytes(2))
    colorMapping[foreground] = {}

    for j = 1, lenColorMappingForeground do
      local background = bytesToInt(readBytes(3))
      local lenColorMappingBackground = bytesToInt(readBytes(2))
      colorMapping[foreground][background] = {}

      for k = 1, lenColorMappingBackground do
        local index = #colorMapping[foreground][background] + 1
        local x = bytesToInt(readBytes(1))
        local y = bytesToInt(readBytes(1))
        local length = bytesToInt(readBytes(1))
        colorMapping[foreground][background][index] = {x, y, getString(length)}
      end
    end
  end
  return backgroundForeground, colorMapping
end

local function drawImage(path)
  local startTime = computer.uptime()
  local backgroundForeground, colorMapping = readFromFile(path)
  startTime = computer.uptime() - startTime
  local drawTime = computer.uptime()
  local foregroundColors = {}
  local backgroundColors = {}

  for foreground, backgroundTable in pairs(colorMapping) do
    foregroundColors[foreground] = true
    for background, pixelTable in pairs(backgroundTable) do
      backgroundColors[background] = true
    end
  end

  for foreground in pairs(foregroundColors) do
    for background in pairs(backgroundColors) do
      local pixels = colorMapping[foreground][background]
      if pixels then
        gpu.setForeground(foreground)
        gpu.setBackground(background)
        for _, pixel in ipairs(pixels) do
          gpu.set(pixel[1], pixel[2], pixel[3])
        end
      end
    end
  end
  drawTime = computer.uptime() - drawTime
  gpu.setForeground(0xffffff)
  gpu.setBackground(0x000000)
  return startTime, drawTime
end

local startTime, drawTime = drawImage(args[1])
if args[2] ~= nil then
  term.setCursor(1, 1)
  print("File Read Time: " .. string.sub(tostring(startTime), 1, 5))
  print("Drawing Time:    " .. string.sub(tostring(drawTime), 1, 5))
end
