local sg = require "sgui"
local component = require "component"
local computer = require "computer"
local term = require "term"

local RebootsCount = 0;

local gpu = component.gpu
local flux = component.flux_controller
local me = component.me_controller
local chat = component.chat_box

local admin = "Stawlie_"
local W, H = 100, 48
local colors = {0x525FE1, 0x525FE1, 0x525FE1, 0xEEE2DE}

local players = {
    -- игроки для проверки на онлайн {"ник", пол (M/W), сообщение, онлайн}
    {"Stawlie_", "M", "Царь батюшка на сервере", false},
    {"NikkyFreaky", "M", "О боже дай мне сил припёрся", false},
    {"KatikoSss", "W", "Не крутая Катя пришла", false},
    {"maxcedx", "M", "Опа, пришел, сноси 200 термоядерок", false},
    {"poiji", "M", nil, false},
    {"TheTzdDark", "M", nil, false},
    {"iluffy", "M", nil, false},
    {"Ka2ua", "M", "Повелитель угля пришел", false},
}
--------------------------------------------------------------
term.clear() -- Чистка экрана
---------------------------------------------------------------
sg.cube(2, 2, 36, 6, colors[3])                                                  --рамка для сети
sg.text(4, 2, "&B[Энерго-система]")

local function energy(eu)
    if eu >= 1000000000 then
        return string.format("%.3f GEU/t", eu / 1000000000)
    elseif eu >= 1000000 then
        return string.format("%.3f MEU/t", eu / 1000000)
    else
        return string.format("%.3f kEU/t", eu / 1000)
    end
end

-- Функция для обновления информации о энергии
function updEnergy()
    local eSusEnergy = flux.getEnergyInfo()
    local outEn, inEn = eSusEnergy.energyOutput, eSusEnergy.energyInput
    sg.text(3, 5, "                               ")
    sg.text(3, 4, "&aСеть: &e" .. flux.getNetworkInfo().name)
    sg.text(3, 5, "&aЭнергия Вход: &2" .. energy(inEn / 4))
    sg.text(3, 6, "&aЭнергия Выход: &4" .. energy(outEn / 4))
end
-----------------------------------------
sg.cube(40, 2, 59, 6, colors[3])                                                 --рамка для игроков
sg.text(42, 2, "&B[Игроки]")

-- Функция для получения сообщения игрока
local function getPlayerMessage(playerName)
    for _, playerData in ipairs(players) do
        if playerData[1] == playerName then
            local message = playerData[3] or "Зашел в игру"
            -- Проверяем пол игрока
            if playerData[2] == "W" then
                message = "Зашла в игру"
            end
            return message
        end
    end
    return "Зашел в игру"  -- Возвращаем сообщение по умолчанию, если игрок не найден
end

local function updPlayers()
    computer.removeUser(admin)

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
        elseif not isOnline and players[i][4] then
            chat.say("§e" .. player .. "§c§l покинул игру!")
            players[i][4] = false
        end

        computer.removeUser(player)
    end
    computer.addUser(admin)
end
------------------------------------------
sg.cube(2, 9, 97, 18, colors[3])                                                 --рамка для процессоров
sg.text(4, 9, "&B[Процессоры создания]")

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

    sg.text(75, 26, "&a&l" .. cp.IDLE .. " &f&l/&4&l " .. cp.BUSY)  -- Вывести количество CPU в работе и свободных
    sg.text(85, 26, "&1&lВсего: &a&l" .. #cpus)  -- Вывести общее количество CPU
end
----------------------------------
sg.cube(2, 28, 97, 19, colors[3])                                                 --рамка для реакторов
sg.text(4, 28, "&B[Реакторы]")

local targetComponentType = "reactor_chamber"

-- Функция для проверки, работает ли реактор
local function isReactorActive(reactorAddress)
    local reactor = component.proxy(reactorAddress)
    if reactor and reactor.getEUOutput then
      return reactor.getEUOutput() >= 1
    end
    return false
end

  local function getReactorEnergyProduction(reactorAddress)
    local reactor = component.proxy(reactorAddress)
    if reactor and reactor.getReactorEUOutput then
      return reactor.getReactorEUOutput()
    end
    return 0
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

function updReactor()
    local reactorAddresses = findComponentAddresses(targetComponentType)
    local reactorsPerColumn = 17
    local totalColumns = 3
    local desiredTotalReactors = 50

    local workingReactors = 0
    local totalEnergyProduction = 0

    for i = 1, desiredTotalReactors do
        local column = math.floor((i - 1) / reactorsPerColumn) % totalColumns
        local row = (i - 1) % reactorsPerColumn + 1

        if reactorAddresses[i] then
            local reactorAddress = reactorAddresses[i]
            local energyProduction = getReactorEnergyProduction(reactorAddress)
            totalEnergyProduction = totalEnergyProduction + energyProduction

            local color = energyProduction >= 10 and "&a" or "&4"
            local reactorInfo = "&fРеактор #" .. i .. ": " .. color .. energy(energyProduction)

            local x = 3 + column * 32
            local y = row + 29
            sg.text(x, y, reactorInfo)

            workingReactors = workingReactors + (energyProduction >= 10 and 1 or 0)
        else
            local x = 3 + column * 32
            local y = row + 29

            sg.text(x, y, "&4Реактор #" .. i .. ": &7Отсутствует!!")
            if RebootsCount == 1 then
                chat.say("§fРеактор #" .. i .. ": §7Отсутствует")
            end
        end
    end

    local nonWorkingReactors = desiredTotalReactors - workingReactors
    local result = "&2&l" .. workingReactors .. "&f&l / &4&l" .. nonWorkingReactors .. "       &2&l" .. energy(totalEnergyProduction)
    sg.text(67, 46, result)
    --sg.text(3 + 2 * 32, 17 + 29, result)
end


--------------------------------------------
local work = true

sg.main(colors[1], W, H, "Конь Педальный")
chat.setName("§9§lКонь Педальный§7§o")

while work do
    updEnergy()
    updPlayers()
    updME() 
    updReactor()

    RebootsCount = RebootsCount + 1

    -- Если RebootsCount достиг 100, сбросить до 1
    if RebootsCount == 120 then
        RebootsCount = 1
        chat.say("Clear buffer")
    end    
    
    os.sleep(0.05)
end