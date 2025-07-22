local component = require("component")
local computer = require("computer")
local term = require("term")
local event = require("event")
local thread = require("thread")
local filesystem = require("filesystem")

local gui = require("sgui")

local MEController = component.isAvailable("me_controller") and component.me_controller or nil
local gpu = component.isAvailable("gpu") and component.gpu or nil
local chatBox = component.isAvailable("chat_box") and component.chat_box or nil
local flux = nil
local fluxComponentNames = {"flux_network", "fluxnetwork", "flux_controller", "fluxnetworks", "flux_plug"}

local debugTest = "Stawlie_"
local debug = true

local function getComponentsByType(componentType)
    local components = {}
    for address, cType in component.list() do
        if cType == componentType then
            table.insert(components, {address = address, type = cType})
        end
    end
    return components
end

for _, name in ipairs(fluxComponentNames) do
    if component.isAvailable(name) then
        flux = component[name]
        break
    end
end

local frames = {
    energy = {x = 2, y = 2, width = 40, height = 8, title = "Энерго-сеть"},
    players = {x = 42, y = 2, width = 0, height = 8, title = "Игроки"},
    reactors = {x = 2, y = 10, width = 0, height = 18, title = "Реакторы"},
    meProcesses = {x = 2, y = 28, width = 0, height = 12, title = "МЭ Процессы создания"},
}

local screenWidth, screenHeight = 120, 40

local function calculateFrameSizes()
    frames.players.width = screenWidth - frames.players.x
    frames.reactors.width = screenWidth - frames.reactors.x
    frames.meProcesses.width = screenWidth - frames.meProcesses.x
end

local function getFrameInnerBounds(frameName)
    local frame = frames[frameName]
    return {
        x = frame.x + 1,
        y = frame.y + 1,
        width = frame.width - 2,
        height = frame.height - 2,
        maxX = frame.x + frame.width - 2,
        maxY = frame.y + frame.height - 2
    }
end

local clearTimers = {
    meController = 0,
    meStats = 0,
}

local CLEAR_INTERVAL = 5

local function shouldClear(timerName)
    local currentTime = computer.uptime()
    if currentTime - clearTimers[timerName] >= CLEAR_INTERVAL then
        clearTimers[timerName] = currentTime
        return true
    end
    return false
end

local function getMEControllerStats()
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

local function renderMEController(controllerData)
    local innerBounds = getFrameInnerBounds("meProcesses")
    local xPos, yPos = innerBounds.x, innerBounds.y + 1
    
    local cpuTextLength = 19
    local maxColumns = math.floor(innerBounds.width / (cpuTextLength + 1))
    if maxColumns < 1 then maxColumns = 1 end
    
    local maxProcessors = 50
    
    if shouldClear("meController") then
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
            if processor.id >= 0 and processor.id <= 9 then
                gui.text(x, y, "&fCPU #" .. processor.id .. ":  " .. statusColor .. processor.status)
            else
                gui.text(x, y, "&fCPU #" .. processor.id .. ": " .. statusColor .. processor.status)
            end
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
    
    if shouldClear("meStats") then
        gui.text(statsX1, statsY, "        ")
        gui.text(statsX2, statsY, "           ")
    end
    
    gui.text(statsX1, statsY, "&a" .. controllerData.stats.idle .. " &f/&4 " .. controllerData.stats.busy)
    gui.text(statsX2, statsY, "&9 Всего: &a" .. controllerData.total)
end

local playersDataFile = "/home/data/playersData.txt"

-- Функция для сохранения данных игроков в файл
local function savePlayersData(data)
    local file = io.open(playersDataFile, "w")
    if file then
        for _, player in ipairs(data) do
            local line = string.format("%s|%s|%s|%s\n", 
                player[1], player[2], player[3], tostring(player[4]))
            file:write(line)
        end
        file:close()
        return true
    end
    return false
end

-- Функция для загрузки данных игроков из файла
local function loadPlayersData()
    local file = io.open(playersDataFile, "r")
    local data = {}
    
    if file then
        for line in file:lines() do
            local name, greeting, farewell, status = line:match("(.+)|(.+)|(.+)|(.+)")
            if name and greeting and farewell and status then
                table.insert(data, {name, greeting, farewell, status == "true"})
            end
        end
        file:close()
    else
        -- Если файл не существует, создаем данные по умолчанию
        data = {
            {"Stawlie_", "Царь батюшка на сервере", "Покинул путь войина", false},
        }
        savePlayersData(data)
    end
    
    return data
end

-- Загружаем данные игроков из файла при запуске
local playersData = loadPlayersData()

local permissions = {}
-- Хэш-таблица разрешений
for i = 1, #playersData do
    local playerName = playersData[i][1]
    if playerName then
        permissions[playerName] = true
    end
end
permissions[debugTest] = true

-- Функция для добавления игрока
local function addPlayer(nick, greeting, farewell)
    greeting = greeting or "Вошел на сервер"
    farewell = farewell or "Покинул сервер"
    
    -- Проверяем, не существует ли уже такой игрок
    for _, player in ipairs(playersData) do
        if player[1] == nick then
            return false, "Игрок уже существует"
        end
    end
    
    table.insert(playersData, {nick, greeting, farewell, false})
    
    if savePlayersData(playersData) then
        return true, "Игрок добавлен успешно"
    else
        return false, "Ошибка сохранения файла"
    end
end

-- Функция для удаления игрока
local function removePlayer(nick)
    for i, player in ipairs(playersData) do
        if player[1] == nick then
            table.remove(playersData, i)
            if savePlayersData(playersData) then
                return true, "Игрок удален успешно"
            else
                return false, "Ошибка сохранения файла"
            end
        end
    end
    return false, "Игрок не найден"
end

-- Функция для обновления приветствия игрока
local function updatePlayerGreeting(nick, greeting)
    for i, player in ipairs(playersData) do
        if player[1] == nick then
            playersData[i][2] = greeting
            if savePlayersData(playersData) then
                return true, "Приветствие обновлено"
            else
                return false, "Ошибка сохранения файла"
            end
        end
    end
    return false, "Игрок не найден"
end

-- Функция для обновления прощания игрока
local function updatePlayerFarewell(nick, farewell)
    for i, player in ipairs(playersData) do
        if player[1] == nick then
            playersData[i][3] = farewell
            if savePlayersData(playersData) then
                return true, "Прощание обновлено"
            else
                return false, "Ошибка сохранения файла"
            end
        end
    end
    return false, "Игрок не найден"
end

function getPlayerMessage(playerName, messageType)
    for _, playerData in ipairs(playersData) do
        if playerData[1] == playerName then
            if messageType == "farewell" then
                return playerData[3] or "Покинул сервер"
            else
                return playerData[2] or "Вошел на сервер"
            end
        end
    end
    return messageType == "farewell" and "Покинул сервер" or "Вошел на сервер"
end

local function processPlayersStatus()
    local playersStatus = {}
    local statusChanges = {}
    
    for i = 1, #playersData do
        computer.removeUser(playersData[i][1])
        if debugTest then
            computer.removeUser(debugTest)
        end
    end
    
    for i = 1, #playersData do
        local player = playersData[i][1]
        local isOnline = computer.addUser(player)
        local wasOnline = playersData[i][4]
        
        playersStatus[i] = {
            name = player,
            isOnline = isOnline,
            wasOnline = wasOnline,
            data = playersData[i]
        }
        
        if isOnline and not wasOnline then
            statusChanges[#statusChanges + 1] = {
                type = "joined",
                player = player,
                message = getPlayerMessage(player, "greeting")
            }
            playersData[i][4] = true
            savePlayersData(playersData)
        elseif not isOnline and wasOnline then
            statusChanges[#statusChanges + 1] = {
                type = "left",
                player = player,
                message = getPlayerMessage(player, "farewell")
            }
            playersData[i][4] = false
            savePlayersData(playersData)
        end
        
        if debugTest then
            computer.addUser(debugTest)
        end
        computer.addUser(playersData[i][1])
    end
    
    return {
        players = playersStatus,
        changes = statusChanges
    }
end

-- Исправленная функция рендера (убрано условие hasChanges)
local function renderPlayersDisplay(processedData)
    local innerBounds = getFrameInnerBounds("players")
    
    local playerNameMaxLength = 20
    local maxColumns = math.floor(innerBounds.width / (playerNameMaxLength + 2))
    if maxColumns < 1 then maxColumns = 1 end
    
    local maxRowsPerColumn = innerBounds.height - 1
    local columnWidth = math.floor(innerBounds.width / maxColumns)
    
    local maxPlayers = maxColumns * maxRowsPerColumn
    
    -- Очищаем область отображения
    for i = 1, maxPlayers do
        local columnIndex = (i - 1) % maxColumns
        local rowIndex = math.floor((i - 1) / maxColumns)
        
        if rowIndex < maxRowsPerColumn then
            local x = innerBounds.x + columnIndex * columnWidth
            local y = innerBounds.y + 1 + rowIndex
            
            if x <= innerBounds.maxX - playerNameMaxLength and y <= innerBounds.maxY then
                gui.text(x, y, string.rep(" ", math.min(columnWidth - 1, playerNameMaxLength)))
            end
        end
    end
    
    -- Отображаем игроков
    for i = 1, #processedData.players do
        local playerInfo = processedData.players[i]
        
        local columnIndex = (i - 1) % maxColumns
        local rowIndex = math.floor((i - 1) / maxColumns)
        
        if rowIndex < maxRowsPerColumn then
            local x = innerBounds.x + columnIndex * columnWidth
            local y = innerBounds.y + 1 + rowIndex
            
            if x <= innerBounds.maxX - playerNameMaxLength and y <= innerBounds.maxY then
                local prefix = ""
                if playerInfo.isOnline then
                    prefix = "&2"  -- Зеленый для онлайн игроков
                else
                    prefix = "&4"  -- Красный для оффлайн игроков
                end
                prefix = prefix .. playerInfo.name
                gui.text(x, y, prefix)
            end
        end
    end
end

local function handleChatMessages(statusChanges)
    if not chatBox then return end
    
    for i = 1, #statusChanges do
        local change = statusChanges[i]
        if change.type == "joined" then
            chatBox.say("§e" .. change.player .. "§a§l " .. change.message)
        elseif change.type == "left" then
            chatBox.say("§e" .. change.player .. "§c§l покинул игру!")
        end
    end
end

local function chatMessageHandler()
    while true do
        local _, address, nick, msg = event.pull(1, "chat_message")
        if permissions[nick] then
            if "@sleep" == msg then
                chatBox.say("§e§lПерезагружаюсь")
                computer.shutdown(true)
            elseif "@help" == msg then
                chatBox.say("Версия программы 2")
                chatBox.say("@clearR - Очистить кэш реакторов")
                chatBox.say("@clearE - Очистить кэш энергии")
                chatBox.say("@add <ник> - Добавить игрока")
                chatBox.say("@remove <ник> - Удалить игрока")
                chatBox.say("@greeting <ник> <текст> - Установить приветствие")
                chatBox.say("@farewell <ник> <текст> - Установить прощание")
            elseif "@clearR" == msg then
                local success, errormsg = os.remove(REACTOR_FILE)
                if success then 
                    chatBox.say("Файл успешно удален. Перезагрузите компьютер!") 
                else 
                    chatBox.say("Не удалось удалить файл: " .. errormsg) 
                end
            elseif "@clearE" == msg then
                local success, errormsg = os.remove("/home/data/energyInfo.txt")
                if success then 
                    chatBox.say("Файл успешно удален. Перезагрузите компьютер!") 
                else 
                    chatBox.say("Не удалось удалить файл: " .. errormsg) 
                end
            elseif msg:match("^@add ") then
                local playerNick = msg:match("^@add (.+)")
                if playerNick then
                    local success, message = addPlayer(playerNick)
                    chatBox.say(message)
                    if success then
                        permissions[playerNick] = true  -- Даем разрешения новому игроку
                    end
                else
                    chatBox.say("Использование: @add <ник>")
                end
            elseif msg:match("^@remove ") then
                local playerNick = msg:match("^@remove (.+)")
                if playerNick then
                    local success, message = removePlayer(playerNick)
                    chatBox.say(message)
                    if success then
                        permissions[playerNick] = nil  -- Убираем разрешения у удаленного игрока
                    end
                else
                    chatBox.say("Использование: @remove <ник>")
                end
            elseif msg:match("^@greeting ") then
                local playerNick, greetingText = msg:match("^@greeting (%S+) (.+)")
                if playerNick and greetingText then
                    local success, message = updatePlayerGreeting(playerNick, greetingText)
                    chatBox.say(message)
                else
                    chatBox.say("Использование: @greeting <ник> <текст>")
                end
            elseif msg:match("^@farewell ") then
                local playerNick, farewellText = msg:match("^@farewell (%S+) (.+)")
                if playerNick and farewellText then
                    local success, message = updatePlayerFarewell(playerNick, farewellText)
                    chatBox.say(message)
                else
                    chatBox.say("Использование: @farewell <ник> <текст>")
                end
            end
        end
    end
end

thread.create(chatMessageHandler)

function ensureDirectoryExists(path)
    if not filesystem.exists(path) then
        filesystem.makeDirectory(path)
    end
end

function loadFileData(fileName)
    ensureDirectoryExists("/home/data")

    local file = io.open(fileName, "r")
    if file then
        local request = tonumber(file:read("*a"))
        file:close()
        return request or 0
    else
        return 0
    end
end

function saveMaxEnergy(maxEnergy, fileName)
    local file = io.open(fileName, "w")
    if file then
        file:write(tostring(maxEnergy))
        file:close()
    end
end

function energy(eu)
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

maxEnergyFile = "/home/data/energyInfo.txt"
maxEnergyFluxNetwork = loadFileData(maxEnergyFile)

local function getFluxNetworkStats()
    if not flux then
        return {
            name = "Flux Network Unavailable",
            input = 0,
            buffer = 0,
            maxInput = 0
        }
    end
    
    local success, nfo = pcall(function() return flux.getNetworkInfo() end)
    if not success then
        return {
            name = "Error: " .. tostring(nfo),
            input = 0,
            buffer = 0,
            maxInput = 0
        }
    end
    
    local success2, e = pcall(function() return flux.getEnergyInfo() end)
    if not success2 then
        return {
            name = nfo.name or "Unknown",
            input = 0,
            buffer = 0,
            maxInput = 0
        }
    end

    if maxEnergyFluxNetwork < e.energyInput then
        maxEnergyFluxNetwork = e.energyInput
        saveMaxEnergy(maxEnergyFluxNetwork, maxEnergyFile)
    end

    return {
        name = nfo.name or "Unknown Network",
        input = e.energyInput or 0,
        buffer = e.totalBuffer or 0,
        maxInput = maxEnergyFluxNetwork
    }
end

local function renderFluxNetwork(stats)
    if not stats then
        gui.text(3, 4, "&cFlux Network: Error")
        return
    end
    gui.text(3, 5, string.rep(" ", 20))
    gui.text(3, 4, "&aСеть:&e " .. tostring(stats.name))

    gui.text(3, 5, string.rep(" ", 20))
    gui.text(3, 5, "&aВход: &2" .. energy(stats.input / 4))

    gui.text(3, 6, string.rep(" ", 20))
    gui.text(3, 6, "&aБуфер:&2 " .. string.sub(energy(stats.buffer), 1, -3))

    gui.text(3, 7, "&aМаксимальный вход:&2 " .. energy(stats.maxInput / 4))
end

local REACTOR_FILE         = "/home/data/reactorInfo.txt"
local REACTOR_UPDATE_INT   = 2
local REACTOR_TEMP_WARN    = 950
local MAX_REACTORS         = 6

local lastReactorUpdate    = 0
local lastReactorCount     = 0
local reactorsClearedOnce  = false
local explosionNotified    = false

local function formatReactorEnergy(rf)
    if rf >= 1000000000000 then
        return string.format("%.2f TRF/t", rf / 1000000000000)
    elseif rf >= 1000000000 then
        return string.format("%.2f GRF/t", rf / 1000000000)
    elseif rf >= 1000000 then
        return string.format("%.2f MRF/t", rf / 1000000)
    elseif rf >= 1000 then
        return string.format("%.2f kRF/t", rf / 1000)
    else
        return string.format("%.0f RF/t", rf)
    end
end

-- Глобальная переменная для отслеживания какой реактор обновлять
local reactorUpdateIndex = 1
local lastReactorData = {} -- Кэш предыдущих значений

local function getNuclearReactorsStats()
    local reactorsAddr = getComponentsByType("htc_reactors_nuclear_reactor")
    local reactorsData = {}

    local totalEnergy, totalCoolant, hottest = 0, 0, 0

    for i = 1, #reactorsAddr do
        local success, r = pcall(function() return component.proxy(reactorsAddr[i].address) end)
        if not success then
            goto continue
        end

        local success2, gen = pcall(function() return r.getEnergyGeneration() end)
        local success3, mb = pcall(function() return r.getFluidCoolantConsume() end)
        local success4, t = pcall(function() return r.getTemperature() end)
        local success5, hasWork = pcall(function() return r.hasWork() end)
        
        -- Новые данные
        local success6, reactorLevel = pcall(function() return r.getReactorLevel() end)
        local success7, reactorType = pcall(function() return r.isActiveCooling() end)
        local success8, isOn = pcall(function() return r.hasWork() end) -- Проверка состояния включения
        
        gen = success2 and gen or 0
        mb = success3 and mb or 0
        t = success4 and t or 0
        hasWork = success5 and hasWork or false
        reactorLevel = success6 and reactorLevel or 0
        isLiquidCooled = success7 and reactorType or false
        isActivated = success8 and isOn or false

        reactorsData[#reactorsData + 1] = {
            id           = i,
            online       = hasWork,
            activated    = isActivated,  -- Включен: On/Off
            level        = reactorLevel, -- Уровень реактора
            type         = isLiquidCooled and "Жидкостный" or "Воздушный", -- Тип реактора
            energyGen    = gen,          -- Энергия
            temp         = t,            -- Температура
            coolant      = mb            -- Потребление жидкости (если жидкостный)
        }

        totalEnergy  = totalEnergy  + gen
        totalCoolant = totalCoolant + mb
        hottest      = math.max(hottest, t)

        ::continue::
    end

    return {
        reactors        = reactorsData,
        count           = #reactorsAddr,
        totalEnergy     = totalEnergy,
        totalCoolant    = totalCoolant,
        hottestTemp     = hottest,
    }
end

local function hasReactorChanged(newReactor, oldReactor)
    if not oldReactor then return true end
    
    return newReactor.online ~= oldReactor.online or
           newReactor.activated ~= oldReactor.activated or
           newReactor.level ~= oldReactor.level or
           newReactor.energyGen ~= oldReactor.energyGen or
           newReactor.temp ~= oldReactor.temp or
           newReactor.coolant ~= oldReactor.coolant or
           newReactor.type ~= oldReactor.type
end

local function renderSingleReactor(reactor, x, y, reactorWidth, reactorHeight)
    local reactorColor = reactor.online and "&a" or "&4"
    local tempColor = reactor.temp >= REACTOR_TEMP_WARN and "&c" or "&f"
    local statusColor = reactor.activated and "&a" or "&4"
    local statusText = reactor.activated and "On" or "Off"
    
    -- Очищаем только область этого реактора
    for lineY = y, y + reactorHeight - 1 do
        gui.text(x, lineY, string.rep(" ", reactorWidth))
    end
    
    -- Выводим данные реактора
    gui.text(x, y, reactorColor .. "Реактор №" .. reactor.id .. " (" .. reactor.type .. ")")
    gui.text(x, y + 1, "&fВключен: " .. statusColor .. statusText)
    gui.text(x, y + 2, "&fУровень: &e" .. string.format("%d", reactor.level))
    gui.text(x, y + 3, "&fЭнергия: &6" .. formatReactorEnergy(reactor.energyGen))
    gui.text(x, y + 4, "&fТемп:    " .. tempColor .. reactor.temp .. "°C")
    if reactor.type == "Жидкостный" then
        gui.text(x, y + 5, "&fРасход:  &b" .. reactor.coolant .. " mB/s")
    else
        -- gui.text(x, y + 5, "&7Воздушное охлаждение")
    end
end

local function renderNuclearReactors(stats)
    local b = getFrameInnerBounds("reactors")
    local cols = 3
    local reactorWidth = math.floor(b.width / cols) - 1
    local reactorHeight = 7
    local separatorWidth = 1
    
    -- Первый раз отрисовываем все реакторы
    if #lastReactorData == 0 then
        for i = 1, math.min(6, #stats.reactors) do
            local reactor = stats.reactors[i]
            local colIndex = (i - 1) % cols
            local rowIndex = math.floor((i - 1) / cols)
            
            local x = b.x + colIndex * (reactorWidth + separatorWidth)
            local y = b.y + rowIndex * (reactorHeight + 1)
            
            renderSingleReactor(reactor, x, y, reactorWidth, reactorHeight)
        end
        lastReactorData = {}
        for i = 1, #stats.reactors do
            lastReactorData[i] = stats.reactors[i]
        end
    else

        if reactorUpdateIndex <= math.min(6, #stats.reactors) then
            local reactor = stats.reactors[reactorUpdateIndex]
            local oldReactor = lastReactorData[reactorUpdateIndex]
            
            if hasReactorChanged(reactor, oldReactor) then
                local colIndex = (reactorUpdateIndex - 1) % cols
                local rowIndex = math.floor((reactorUpdateIndex - 1) / cols)
                
                local x = b.x + colIndex * (reactorWidth + separatorWidth)
                local y = b.y + rowIndex * (reactorHeight + 1)
                
                renderSingleReactor(reactor, x, y, reactorWidth, reactorHeight)
                lastReactorData[reactorUpdateIndex] = reactor
            end
        end
        
        reactorUpdateIndex = reactorUpdateIndex + 1
        if reactorUpdateIndex > math.min(6, #stats.reactors) then
            reactorUpdateIndex = 1
        end
    end
    
    if stats.count > 0 then
        local summaryY = b.maxY
        local clearWidth = 70
        gui.text(b.x, summaryY, string.rep(" ", clearWidth))
        gui.text(b.x, summaryY, string.format("&fΣ: &6%s &b%s mB/s &fРеакторов: &e%d", 
            formatReactorEnergy(stats.totalEnergy), stats.totalCoolant, stats.count))
    end
end

local TableTitle = "&4[Мониторинг]"
local ChatTitle = "Оператор"

local function notifyReactorExplosion(missingCount, totalFound, maxExpected)
    if not chatBox then return end
    
    chatBox.setName("§c§lВНИМАНИЕ§7§o")
    
    if missingCount == 1 then
        chatBox.say("§c§l⚠ ВЗРЫВ РЕАКТОРА! ⚠")
        chatBox.say("§cОтсутствует §e1 §cреактор! Обнаружено: §e" .. totalFound .. "§c из §e" .. maxExpected)
    else
        chatBox.say("§c§l⚠ ВЗРЫВ РЕАКТОРОВ! ⚠")
        chatBox.say("§cОтсутствует §e" .. missingCount .. " §cреакторов! Обнаружено: §e" .. totalFound .. "§c из §e" .. maxExpected)
    end
    
    chatBox.say("§c§lПроверьте реакторную зону немедленно!")
    
    chatBox.setName("§9§l" .. ChatTitle .. "§7§o")
end

local function updateReactors()
    local now = computer.uptime()
    if now - lastReactorUpdate < REACTOR_UPDATE_INT then return end
    lastReactorUpdate = now

    local stats = getNuclearReactorsStats()
    local maxStored = loadFileData(REACTOR_FILE)

    if maxStored == 0 or stats.count > maxStored then
        maxStored = math.max(stats.count, MAX_REACTORS)
        saveMaxEnergy(maxStored, REACTOR_FILE)
    end

    local missingReactors = maxStored - stats.count
    
    if stats.count < maxStored and missingReactors > 0 then
        if lastReactorCount ~= stats.count and lastReactorCount > 0 then
            explosionNotified = true
            notifyReactorExplosion(missingReactors, stats.count, maxStored)
        end
    else
        if stats.count == maxStored then
            explosionNotified = false
        end
    end

    lastReactorCount = stats.count

    renderNuclearReactors(stats)
end

term.clear()

if gpu then
    gpu.setResolution(screenWidth, screenHeight)
    
    calculateFrameSizes()
    
    gui.drawMain("&d" .. TableTitle, gui.colors["border"], "2")
    gui.drawFrame(frames.energy.x, frames.energy.y, frames.energy.width, frames.energy.height, frames.energy.title, gui.colors["border"])
    gui.drawFrame(frames.players.x, frames.players.y, frames.players.width, frames.players.height, frames.players.title, gui.colors["border"])
    gui.drawFrame(frames.reactors.x, frames.reactors.y, frames.reactors.width, frames.reactors.height, frames.reactors.title, gui.colors["border"])
    gui.drawFrame(frames.meProcesses.x, frames.meProcesses.y, frames.meProcesses.width, frames.meProcesses.height, frames.meProcesses.title, gui.colors["border"])
end

if chatBox then
    chatBox.setName("§9§l" .. ChatTitle .. "§7§o")
end

while true do
    local meData = getMEControllerStats()
    local playersData_processed = processPlayersStatus()
    
    renderMEController(meData)
    renderPlayersDisplay(playersData_processed)
    renderFluxNetwork(getFluxNetworkStats())
    
    updateReactors()
    
    handleChatMessages(playersData_processed.changes)
    
    computer.pullSignal(0.1)
end