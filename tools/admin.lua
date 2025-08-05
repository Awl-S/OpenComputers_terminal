local filesystem = require("filesystem")
local args = {...}

local playersDataFile = "/home/data/playersData.txt"

local function ensureDirectoryExists(path)
    if not filesystem.exists(path) then
        filesystem.makeDirectory(path)
    end
end

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
    end
    
    return data
end

local function savePlayersData(data)
    ensureDirectoryExists("/home/data")
    
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

local function addPlayer(nick, greeting, farewell)
    local playersData = loadPlayersData()
    
    greeting = greeting or "Администратор зашёл на сервер"
    farewell = farewell or "Администратор покинул сервер"
    
    -- Проверяем, не существует ли уже такой игрок
    for _, player in ipairs(playersData) do
        if player[1] == nick then
            print("Ошибка: Игрок '" .. nick .. "' уже существует в базе данных")
            return false
        end
    end
    
    table.insert(playersData, {nick, greeting, farewell, false})
    
    if savePlayersData(playersData) then
        print("Успешно: Игрок '" .. nick .. "' добавлен в базу данных")
        print("Приветствие: " .. greeting)
        print("Прощание: " .. farewell)
        return true
    else
        print("Ошибка: Не удалось сохранить файл данных")
        return false
    end
end

local function removePlayer(nick)
    local playersData = loadPlayersData()
    
    for i, player in ipairs(playersData) do
        if player[1] == nick then
            table.remove(playersData, i)
            if savePlayersData(playersData) then
                print("Успешно: Игрок '" .. nick .. "' удален из базы данных")
                return true
            else
                print("Ошибка: Не удалось сохранить файл после удаления")
                return false
            end
        end
    end
    print("Ошибка: Игрок '" .. nick .. "' не найден в базе данных")
    return false
end

local function listPlayers()
    local playersData = loadPlayersData()
    
    if #playersData == 0 then
        print("База данных игроков пуста")
        return
    end
    
    print("Список игроков в базе данных:")
    print("=" .. string.rep("=", 60))
    for i, player in ipairs(playersData) do
        local status = player[4] and "онлайн" or "оффлайн"
        print(string.format("%d. %s (%s)", i, player[1], status))
        print("   Приветствие: " .. player[2])
        print("   Прощание: " .. player[3])
        print()
    end
end

local function showHelp()
    print("Использование: admin.lua <команда> [параметры]")
    print()
    print("Доступные команды:")
    print("  add <ник> [приветствие] [прощание]  - Добавить игрока")
    print("  remove <ник>                        - Удалить игрока")
    print("  list                                - Показать всех игроков")
    print("  help                                - Показать эту справку")
    print()
    print("Примеры:")
    print("  admin.lua add giver345")
    print("  admin.lua add player123 \"Админ подключился\" \"Админ отключился\"")
    print("  admin.lua remove oldplayer")
    print("  admin.lua list")
end

if #args == 0 then
    showHelp()
    return
end

local command = args[1]:lower()

if command == "add" then
    if #args < 2 then
        print("Ошибка: Не указан ник игрока")
        print("Использование: admin.lua add <ник> [приветствие] [прощание]")
        return
    end
    
    local nick = args[2]
    local greeting = args[3]
    local farewell = args[4]
    
    addPlayer(nick, greeting, farewell)
    
elseif command == "remove" then
    if #args < 2 then
        print("Ошибка: Не указан ник игрока")
        print("Использование: admin.lua remove <ник>")
        return
    end
    
    local nick = args[2]
    removePlayer(nick)
    
elseif command == "list" then
    listPlayers()
    
elseif command == "help" then
    showHelp()
    
else
    print("Ошибка: Неизвестная команда '" .. command .. "'")
    showHelp()
end