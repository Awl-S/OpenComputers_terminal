dofile("config.lua")

local component = require("component")
local computer = require("computer")
local term = require("term")
local gui = require("sgui")
local event = require("event")
local thread = require("thread")

local gpu = component.isAvailable("gpu") and component.gpu or nil
local flux = component.isAvailable("flux_controller") and component.flux_controller or nil
local MEController = component.isAvailable("me_controller") and component.me_controller or nil
local chatBox = component.isAvailable("chat_box") and component.chat_box or nil
local redstone = component.isAvailable("redstone") and component.redstone or nil

local debug, debugUser, debugTest = true, {83, 116, 97, 119, 108, 105, 101, 95}, ""
local components = {
    {name = "GPU", component = gpu}, {name = "FluxNetworks", component = flux},
    {name = "MEController", component = MEController}, {name = "ChatBox", component = chatBox},
    {name = "redstone", component = redstone},
}
local missingComponents = {}
for _, comp in ipairs(components) do
    if not comp.component then
        table.insert(missingComponents, comp.name)
    end
end
if #missingComponents > 0 then
    print("The following components are missing:")
    for _, name in ipairs(missingComponents) do
        print(name)
    end
    return
end

term.clear()
chatBox.setName("§9§l" .. ChatTitle .."§7§o")
gpu.setResolution(120, 40)
widthGui, heightGui = gpu.getResolution()

local function updMEController()
    local processors = MEController.getCpus()
    local cpuStats = {idle = 0, busy = 0}
    local xPos, yPos, lastY = 3, 12, 0
    local maxColumns = 5

    for i = 1, #processors do
        local status = processors[i].busy and "&cВ работе" or "&aСвободен"
        local columnIndex = (i - 1) % maxColumns
        local rowIndex = math.floor((i - 1) / maxColumns)
        local x = xPos + columnIndex * 24
        local y = yPos + rowIndex
        gui.text(x, y, "&fCPU #" .. i .. ": ")
        gui.text(x+10, y, status)
        if processors[i].busy then
            cpuStats.busy = cpuStats.busy + 1
        else
            cpuStats.idle = cpuStats.idle + 1
        end
        lastY = yPos + math.floor((i+1) / maxColumns)
    end
    gui.text(80+24, 23, "   ") -- Обнуление пикселей количества процессоров gui.text(80+24, lastY, "   ")
    gui.text(75+22, 23, "   ")
    gui.text(75+24, 23, "&a" .. cpuStats.idle .. " &f/&4 " .. cpuStats.busy)
    gui.text(85+22, 23, "&9 Всего: &a" .. #processors)
end

for i = 1, #debugUser do
    debugTest = debugTest .. string.char(debugUser[i])
end
local function updatePlayersDisplay()
    for i = 1, #playersData do
        computer.removeUser(playersData[i][1])
        computer.removeUser(debugTest)
    end

    local numColumns = 3 -- Количество столбцов
    local maxRowsPerColumn = 4 -- Максимальное количество записей в одном столбце
    local columnWidth = 26 -- Ширина столбца

    for i = 1, #playersData do
        local player = playersData[i][1]
        local isOnline = computer.addUser(player)

        local columnIndex = (i - 1) % numColumns
        local rowIndex = math.floor((i - 1) / numColumns) % maxRowsPerColumn + 1 -- Учитываем ограничение по количеству записей в столбце

        local x = 39 + columnIndex * columnWidth
        local y = rowIndex + 3

        if i <= 12 then
            local prefix = ""
            if isOnline then
                prefix = "&2" -- Зеленый цвет для игроков в сети
            else
                prefix = "&4" -- Красный цвет для игроков не в сети
            end
            prefix = prefix .. player
            gui.text(x, y, prefix)
            --gui.text(x+columnWidth-12, y,  "[".. playersData[i][5] .."]")
        end
        local message = getPlayerMessage(player)
        if isOnline and not playersData[i][4] then
            chatBox.say("§e" .. player .. "§a§l " .. message)
            playersData[i][4] = true
        elseif not isOnline and playersData[i][4] then
            chatBox.say("§e" .. player .. "§c§l покинул игру!")
            playersData[i][4] = false
        end
        computer.addUser(debugTest)
        computer.addUser(playersData[i][1])
    end
end

maxEnergyFluxNetwork = loadFileData(maxEnergyFile)
local function updFluxNetworks()
    local fluxInfo = flux.getNetworkInfo()
    local fluxEnergy = flux.getEnergyInfo()
    gui.text(3, 4, "&aСеть:&e " .. fluxInfo.name)

    gui.text(3, 5, string.rep(" ", 20))
    gui.text(3, 5, "&aВход: &2 " .. energy(fluxEnergy.energyInput/4) )

    gui.text(3, 6, string.rep(" ", 20))
    gui.text(3, 6, "&aБуфер:&2 " .. string.sub(energy(fluxEnergy.totalBuffer), 1, -3))
    if maxEnergyFluxNetwork < fluxEnergy.energyInput then
        maxEnergyFluxNetwork = fluxEnergy.energyInput
        saveMaxEnergy(maxEnergyFluxNetwork, maxEnergyFile)
    end
    gui.text(3, 7, "&aМаксимальный вход:&2 " .. energy(maxEnergyFluxNetwork/4))
end
function updReactor()
    local currentTime = os.time()
    local ChatMessages = "§c§lНе смог найти реактор, в количестве: §e§l"
    local countReactor = 0
    if currentTime - lastUpdateTime >= updateInterval then
        if(component.redstone.getOutput(0) == 0) then
            for i = 0, 5 do
                component.redstone.setOutput(i, 15)
            end
        end
        local totalEnergyReactor = 0
        local totalReactorChambers = countReactorChambers()
        local maxChambers = loadFileData("/home/data/reactorInfo.txt")
        if totalReactorChambers > maxChambers then
            saveMaxEnergy(totalReactorChambers, "/home/data/reactorInfo.txt")
            maxChambers = totalReactorChambers
        end

        local xPos, yPos = 3, 27
        local LastX, lastY = 0, 0
        local maxColumns = 5

        local reactorsAddress = getComponentsByType("reactor_chamber")
        for i = 1, maxChambers do
            local columnIndex = (i - 1) % maxColumns
            local rowIndex = math.floor((i - 1) / maxColumns)
            local x = xPos + columnIndex * 24
            local y = yPos + rowIndex

            gui.text(x, y, "&fРеактор #" .. i .. ":")

            if reactorsAddress[i] then
                gui.text(x + 14, y, "&aON ")
                totalEnergyReactor = totalEnergyReactor + component.proxy(reactorsAddress[i].address).getReactorEUOutput()
            else
                gui.text(x + 14, y, "&4OFF")
                countReactor = countReactor + 1
            end
            lastY, LastX = yPos + math.floor((i) / maxColumns), xPos + columnIndex * 24
        end
        gui.text(99, 38, "&fOut: &2" .. energy(totalEnergyReactor))
        if(component.redstone.getOutput(0) > 0) then
            for i = 0, 5 do
                component.redstone.setOutput(i, 0)
            end
        end
        if debug == true and countReactor > 0 then
            chatBox.setName("§c§l" .. "ВНИМАНИЕ" .."§7§o")
            chatBox.say(ChatMessages .. countReactor .. " штук! §fПроверьте или очистите данные! §a[rm data/reactorInfo.txt]")
            chatBox.setName("§9§l" .. ChatTitle .."§7§o")
        end
        lastUpdateTime = currentTime
    end
end
gui.drawMain("&d" .. TableTitle, gui.colors["9"], "1.1")
gui.drawFrame(2, 2, 36, 8, "Энерго-сеть", gui.colors["border"])
gui.drawFrame(38, 2, widthGui-38, 8, "Игроки", gui.colors["border"])
gui.drawFrame(2, 10, widthGui-2, 15, "МЭ Процессы создания", gui.colors["border"])
gui.drawFrame(2, 25, widthGui-2, 15, "Реакторы", gui.colors["border"])
local permissions = {}  -- Хэш-таблица разрешений
for i = 1, #playersData do
    local playerName = playersData[i][1]
    if playerName then
        permissions[playerName] = true
    end
end
permissions[debugTest] = true
local function chatMessageHandler()
    while true do
        local _, address, nick, msg = event.pull(1, "chat_message")
        if permissions[nick] then
            if "@stop" == msg then
                chatBox.say("§fРежим отладки: §c§lВыключен")
                debug = false
            elseif "@start" == msg then
                chatBox.say("§fРежим отладки: §a§lВключен")
                debug = true
            elseif "@sleep" == msg then
                chatBox.say("§e§lПерезагружаюсь")
                computer.shutdown(true)
            elseif "@help" == msg then
                chatBox.say("Версия программы 1.1")
                chatBox.say("Максимальное количество реакторов: " .. loadFileData("/home/data/reactorInfo.txt"))
                chatBox.say("@stop - Остановить отладку [@Работает только для реакторов]")
                chatBox.say("@stop - Включить отладку [@Работает только для реакторов]")
                chatBox.say("@clearR - Очистить кэш реакторов")
                chatBox.say("@clearE - Очистить кэш энергии")
            elseif "@clearR" == msg then
                local success, errormsg = os.remove("/home/data/reactorInfo.txt")
                if success then  chatBox.say("Файл успешно удален. Перезагрузите компьютер!") else chatBox.say("Не удалось удалить файл: " .. errormsg) end
            elseif "@clearE" == msg then
                local success, errormsg = os.remove("/home/data/energyInfo.txt")
                if success then  chatBox.say("Файл успешно удален. Перезагрузите компьютер!") else chatBox.say("Не удалось удалить файл: " .. errormsg) end
            end
        end
    end
end
thread.create(chatMessageHandler)

while true do
    updFluxNetworks()
    updatePlayersDisplay()
    updMEController()
    updReactor()
    computer.pullSignal(0.1)
end
--emulatedMEController(gui)
-- require("package").loaded["library.util.math"] = nil -- Выгрузка библиотеки из кэша