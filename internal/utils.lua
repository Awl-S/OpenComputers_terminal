local component = require("component")
local filesystem = require("filesystem")
local computer = require("computer")

local utils = {}

local CLEAR_INTERVAL = 5
local clearTimers = {
    meController = 0,
    meStats = 0,
}

function utils.getComponentsByType(componentType)
    local components = {}
    for address, cType in component.list() do
        if cType == componentType then
            table.insert(components, {address = address, type = cType})
        end
    end
    return components
end

function utils.getFrameInnerBounds(frame)
    return {
        x = frame.x + 1,
        y = frame.y + 1,
        width = frame.width - 2,
        height = frame.height - 2,
        maxX = frame.x + frame.width - 2,
        maxY = frame.y + frame.height - 2
    }
end

function utils.shouldClear(timerName)
    local currentTime = computer.uptime()
    if currentTime - clearTimers[timerName] >= CLEAR_INTERVAL then
        clearTimers[timerName] = currentTime
        return true
    end
    return false
end

function utils.ensureDirectoryExists(path)
    if not filesystem.exists(path) then
        filesystem.makeDirectory(path)
    end
end

function utils.loadFileData(fileName)
    utils.ensureDirectoryExists("/home/data")
    
    local file = io.open(fileName, "r")
    if file then
        local data = tonumber(file:read("*a"))
        file:close()
        return data or 0
    end
    return 0
end

function utils.saveFileData(data, fileName)
    local file = io.open(fileName, "w")
    if file then
        file:write(tostring(data))
        file:close()
        return true
    end
    return false
end

function utils.formatEnergy(eu)
    if eu >= 1000000000000 then
        return string.format("%.3f TEU/t", eu / 1000000000000)
    elseif eu >= 1000000000 then
        return string.format("%.3f GEU/t", eu / 1000000000)
    elseif eu >= 1000000 then
        return string.format("%.3f MEU/t", eu / 1000000)
    elseif eu >= 1000 then
        return string.format("%.3f kEU/t", eu / 1000)
    else
        return string.format("%.3f EU/t", eu)
    end
end

return utils