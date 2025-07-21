-- Author: https://github.com/Awl-S

local component = require("component")
local gui = require("sgui")
local utils = require("internal/utils")

local mecontroller = {}

local function getMEController()
    return component.isAvailable("me_controller") and component.me_controller or nil
end

function mecontroller.getStats()
    local MEController = getMEController()
    if not MEController then
        return {processors = {}, stats = {idle = 0, busy = 0}, total = 0}
    end
    
    local success, processors = pcall(function() return MEController.getCpus() end)
    if not success then
        return {processors = {}, stats = {idle = 0, busy = 0}, total = 0}
    end
    
    local cpuStats = {idle = 0, busy = 0}
    local processorsData = {}
    
    for i = 1, #processors do
        local isWorking = processors[i].busy
        local status = isWorking and "В работе" or "Свободен"
        
        processorsData[i] = {
            id = i,
            busy = isWorking,
            status = status
        }
        
        if isWorking then
            cpuStats.busy = cpuStats.busy + 1
        else
            cpuStats.idle = cpuStats.idle + 1
        end
    end
    
    return {
        processors = processorsData,
        stats = cpuStats,
        total = #processors
    }
end

function mecontroller.render(controllerData, innerBounds)
    local xPos, yPos = innerBounds.x, innerBounds.y + 1
    
    local cpuTextLength = 19
    local maxColumns = math.floor(innerBounds.width / (cpuTextLength + 1))
    if maxColumns < 1 then maxColumns = 1 end
    
    local maxProcessors = 50
    
    if utils.shouldClear("meController") then
        for i = 1, maxProcessors do
            local columnIndex = (i - 1) % maxColumns
            local rowIndex = math.floor((i - 1) / maxColumns)
            local x = xPos + columnIndex * (cpuTextLength + 1)
            local y = yPos + rowIndex
            
            if y <= innerBounds.maxY - 2 and x <= innerBounds.maxX - cpuTextLength then
                gui.text(x, y, string.rep(" ", cpuTextLength))
            end
        end
    end
    
    for i = 1, #controllerData.processors do
        local processor = controllerData.processors[i]
        local statusColor = processor.busy and "&c" or "&a"
        local columnIndex = (i - 1) % maxColumns
        local rowIndex = math.floor((i - 1) / maxColumns)
        local x = xPos + columnIndex * (cpuTextLength + 1)
        local y = yPos + rowIndex
        
        if y <= innerBounds.maxY - 2 and x <= innerBounds.maxX - cpuTextLength then
            gui.text(x, y, "&fCPU #" .. processor.id .. ": " .. statusColor .. processor.status)
        end
    end
    
    local statsY = innerBounds.maxY 
    local statsX1 = innerBounds.x + 90
    local statsX2 = innerBounds.x + 120
    
    if statsX1 > innerBounds.maxX - 15 then
        statsX1 = innerBounds.maxX - 15
    end
    if statsX2 > innerBounds.maxX - 15 then
        statsX2 = innerBounds.maxX - 15
    end
    
    if utils.shouldClear("meStats") then
        gui.text(statsX1, statsY, "        ")
        gui.text(statsX2, statsY, "           ")
    end
    
    gui.text(statsX1, statsY, "&a" .. controllerData.stats.idle .. " &f/&4 " .. controllerData.stats.busy)
    gui.text(statsX2, statsY, "&9 Всего: &a" .. controllerData.total)
end

return mecontroller