-- Applied Energistics Library
-- Author: https://github.com/Awl-S

local applied_energistics = {}

-- Зависимости
local component = nil
local gui = nil
local utils = nil
local computer = nil

-- Внутренние переменные
local clearTimers = {
    meController = 0,
    meStats = 0,
}

local CLEAR_INTERVAL = 5
local ME_CONTROLLER_TYPE = "me_controller"

-- Инициализация библиотеки
function applied_energistics.init(dependencies)
    component = dependencies.component
    gui = dependencies.gui
    utils = dependencies.utils
    computer = dependencies.computer
    
    if not component or not gui or not utils or not computer then
        error("Applied Energistics: Missing required dependencies")
    end
end

-- Проверка доступности ME контроллера
function applied_energistics.isAvailable()
    if not component then
        return false
    end
    return component.isAvailable(ME_CONTROLLER_TYPE)
end

-- Проверка необходимости очистки
local function shouldClear(timerName)
    local currentTime = computer.uptime()
    if currentTime - clearTimers[timerName] >= CLEAR_INTERVAL then
        clearTimers[timerName] = currentTime
        return true
    end
    return false
end

-- Получение статистики ME контроллера
function applied_energistics.getData()
    if not applied_energistics.isAvailable() then
        return {
            processors = {},
            stats = {idle = 0, busy = 0},
            total = 0,
            error = "ME Controller not available"
        }
    end
    
    local meController = component[ME_CONTROLLER_TYPE]
    local success, processors = pcall(function() return meController.getCpus() end)
    
    if not success then
        return {
            processors = {},
            stats = {idle = 0, busy = 0},
            total = 0,
            error = "Failed to get CPU data: " .. tostring(processors)
        }
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
        total = #processors,
        error = nil
    }
end

-- Отрисовка ME процессоров
function applied_energistics.render(data, bounds)
    if not gui or not bounds then
        return
    end
    
    if data.error then
        gui.text(bounds.x, bounds.y + 1, "&cError: " .. data.error)
        return
    end
    
    local xPos, yPos = bounds.x, bounds.y + 1
    local cpuTextLength = 19
    local maxColumns = math.floor(bounds.width / (cpuTextLength + 1))
    if maxColumns < 1 then maxColumns = 1 end
    
    local maxProcessors = 50
    
    -- Очистка области если необходимо
    if shouldClear("meController") then
        for i = 1, maxProcessors do
            local columnIndex = (i - 1) % maxColumns
            local rowIndex = math.floor((i - 1) / maxColumns)
            local x = xPos + columnIndex * (cpuTextLength + 1)
            local y = yPos + rowIndex
            
            if y <= bounds.maxY - 2 and x <= bounds.maxX - cpuTextLength then
                gui.text(x, y, string.rep(" ", cpuTextLength))
            end
        end
    end
    
    -- Отрисовка процессоров
    for i = 1, #data.processors do
        local processor = data.processors[i]
        local statusColor = processor.busy and "&c" or "&a"
        local columnIndex = (i - 1) % maxColumns
        local rowIndex = math.floor((i - 1) / maxColumns)
        local x = xPos + columnIndex * (cpuTextLength + 1)
        local y = yPos + rowIndex
        
        if y <= bounds.maxY - 2 and x <= bounds.maxX - cpuTextLength then
            local cpuText
            if processor.id >= 0 and processor.id <= 9 then
                cpuText = "&fCPU #" .. processor.id .. ":  " .. statusColor .. processor.status
            else
                cpuText = "&fCPU #" .. processor.id .. ": " .. statusColor .. processor.status
            end
            gui.text(x, y, cpuText)
        end
    end
    
    -- Отрисовка статистики
    local statsY = bounds.maxY
    local statsX1 = bounds.x + 90
    local statsX2 = bounds.x + 120
    
    if statsX1 > bounds.maxX - 15 then
        statsX1 = bounds.maxX - 15
    end
    if statsX2 > bounds.maxX - 15 then
        statsX2 = bounds.maxX - 15
    end
    
    -- Очистка статистики если необходимо
    if shouldClear("meStats") then
        gui.text(statsX1, statsY, "        ")
        gui.text(statsX2, statsY, "           ")
    end
    
    gui.text(statsX1, statsY, "&a" .. data.stats.idle .. " &f/&4 " .. data.stats.busy)
    gui.text(statsX2, statsY, "&9 Всего: &a" .. data.total)
end

-- Обработка команд
function applied_energistics.handleCommand(cmd, args, chatBox)
    if cmd == "@clearE" then
        if utils and utils.removeFile then
            local success, errormsg = utils.removeFile("/home/data/energyInfo.txt")
            if success then
                if chatBox then
                    chatBox.say("Файл успешно удален. Перезагрузите компьютер!")
                end
                return true, "Файл успешно удален. Перезагрузите компьютер!"
            else
                if chatBox then
                    chatBox.say("Не удалось удалить файл: " .. errormsg)
                end
                return false, "Не удалось удалить файл: " .. errormsg
            end
        else
            return false, "Utils dependency not available"
        end
    end
    
    return false, "Unknown command: " .. cmd
end

return applied_energistics