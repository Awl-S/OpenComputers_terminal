dofile("config.lua")

local sg = require "sgui"
local component = require "component"
local computer = require "computer"
local term = require "term"
local thread = require "thread"

local gpu = component.gpu
local flux = component.flux_controller
local me = component.me_controller
local chat = component.chat_box

term.clear() -- Чистка экрана

local nonWorkingReactors = 0
local nonWorkingID = {}

chat.setName("§9§l" .. nameChat .."§7§o")
----------------------------------------------
-- Функция для обновления информации о энергии
local function updEnergy()
    local eSusEnergy = flux.getEnergyInfo()
    local outEn, inEn = eSusEnergy.energyOutput, eSusEnergy.energyInput
    sg.text(3, 5, "                               ")
    sg.text(3, 4, "&aСеть: &e" .. flux.getNetworkInfo().name)
    sg.text(3, 5, "&aЭнергия Вход: &2" .. sg.energy(inEn / 4))
    sg.text(3, 6, "&aЭнергия Выход: &4" .. sg.energy(outEn / 4))
end
----------------------------------------------
-- Таблица и оповещение в чат
local function updPlayers()
    for i = 1, #players do
        computer.removeUser(players[i][1])
    end

    local numColumns = 3 -- Количество столбцов
    local columnWidth = 20 -- Ширина столбца (в символах)
    local numRows = math.ceil(#players / numColumns) -- Количество строк

    for i = 1, #players do
        local player = players[i][1]
        local isTargetPlayer = player == targetPlayer
        local isOnline = computer.addUser(player)

        local columnIndex = (i - 1) % numColumns -- Вычисляем индекс текущего столбца (0, 1, или 2)
        local rowIndex = math.floor((i - 1) / numColumns) + 1 -- Вычисляем индекс текущей строки

        local x = 42 + columnIndex * columnWidth -- Горизонтальная позиция для текущего столбца
        local y = rowIndex + 3 -- Вертикальная позиция для текущей строки

        local prefix = ""
        if isOnline then
            prefix = "&2" -- Зеленый цвет для игроков в сети
        else
            prefix = "&4" -- Красный цвет для игроков не в сети
        end
        prefix = prefix .. player
        sg.text(x, y, prefix)

        local message = getPlayerMessage(player)
        if isOnline and not players[i][4] then
            chat.say("§e" .. player .. "§a§l " .. message)
            players[i][4] = true
            chat.say();
            debugReactor(nonWorkingReactors, nonWorkingID, chat)
        elseif not isOnline and players[i][4] then
            chat.say("§e" .. player .. "§c§l покинул игру!")
            players[i][4] = false
        end
    end
    -- Даёт право на взаимодействие (редактирование и выключение) компьютера
    for i = 1, #players do
        computer.addUser(players[i][1]) -- Работает только для online users
    end
end

-- Функция для поиска всех адресов компонентов заданного типа
function findComponentAddresses(targetComponentType)
    local addresses = {}
    for address, componentType in component.list() do
        if componentType == targetComponentType then
            table.insert(addresses, address)
        end
    end
    return addresses
end

local function updReactor()
    local reactorAddresses = findComponentAddresses(targetComponentType)
    local reactorsPerColumn = 17
    local totalColumns = 3

    local workingReactors = 0
    local totalEnergyProduction = 0

    nonWorkingID = {}
    nonWorkingReactors = 0

    for i = 1, desiredTotalReactors do
        local column = math.floor((i - 1) / reactorsPerColumn) % totalColumns
        local row = (i - 1) % reactorsPerColumn + 1

        if reactorAddresses[i] then
            local reactorAddress = reactorAddresses[i]
            local energyProduction = getReactorEnergyProduction(reactorAddress)
            totalEnergyProduction = totalEnergyProduction + energyProduction

            local color = energyProduction >= 10 and "&a" or "&4"
            local reactorInfo = "&fРеактор #" .. i .. ": " .. color .. sg.energy(energyProduction)

            local x = 3 + column * 32
            local y = row + 29
            sg.text(x, y, reactorInfo)

            workingReactors = workingReactors + (energyProduction >= 10 and 1 or 0)
        else
            local x = 3 + column * 32
            local y = row + 29
            sg.text(x, y, "&4Реактор #" .. i .. ": &7Отсутствует!!")
            table.insert(nonWorkingID, i)
            nonWorkingReactors = nonWorkingReactors + 1
        end
    end
    local result = "&2&l" .. workingReactors .. "&f&l / &4&l" .. nonWorkingReactors .. "       &2&l" .. sg.energy(totalEnergyProduction)
    sg.text(67, 46, result)
end

function updME()
    local cpus = me.getCpus()  -- Получить информацию о CPU
    local cp = {IDLE = 0, BUSY = 0}  -- Инициализировать счетчики
    local row, col = 2, 0  -- Текущая строка и столбец
    for i = 1, #cpus do
        local status = cpus[i].busy and "&cВ работе" or "&aСвободен"
        sg.text(3 + col * 24, row + 9, "&fCPU #" .. i .. ": " .. status)

        if cpus[i].busy then
            cp.BUSY = cp.BUSY + 1
        else
            cp.IDLE = cp.IDLE + 1
        end

        col = col + 1
        if col >= 4 then
            col = 0
            row = row + 1
        end
    end
    sg.text(80, 26, "   ")
    sg.text(75, 26, "   ")
    sg.text(75, 26, "&a&l" .. cp.IDLE .. " &f&l/&4&l " .. cp.BUSY)  -- Вывести количество CPU в работе и свободных
    sg.text(85, 26, "&1&lВсего: &a&l" .. #cpus)  -- Вывести общее количество CPU
end

while true do
    -- Обновление экрана - обновляет всё содержимое экрана, включая сломанный текст
    if timerUpdate == 1200 then
        term.clear()
        sg.cube(2, 2, 36, 6, colors[3])                                                  --рамка для сети
        sg.text(4, 2, "&B[Энерго-система]")
        sg.cube(2, 28, 97, 19, colors[3])                                                 --рамка для реакторов
        sg.text(4, 28, "&B[Реакторы]")
        sg.cube(2, 9, 97, 18, colors[3])                                                 --рамка для процессоров
        sg.text(4, 9, "&B[Процессоры создания]")
        sg.cube(40, 2, 59, 6, colors[3])                                                 --рамка для игроков
        sg.text(42, 2, "&B[Игроки]")
        sg.main(colors[1], W, H, nameTable)
        timerUpdate = 0
    end
    updEnergy()
    updME()
    updReactor()
    updPlayers()

    if timerReactor == 100 then
        timerReactor = 0;
    end
    timerReactor = timerReactor + 1;
    timerUpdate = timerUpdate + 1
    os.sleep(0.05)
end