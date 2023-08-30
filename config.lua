local component = require("component")
local fs = require("filesystem")  -- Use the file system component for directory checks.

playersData = { --До 12 игроков, далее все игроки будут скрыты, но уведомления будут в чате
    -- игроки для проверки на онлайн {"ник", пол (M/W), сообщение, онлайн, "10:40" - не обязательна, временно не трогать}
    {"Stawlie_", "M", "Царь батюшка на сервере", false, "10:40"}, -- 1

    --{"", "W", nil, false},
}

TableTitle = "&4[Мониторинг]"
ChatTitle = "Оператор"

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

maxEnergyFile = "/home/data/energyInfo.txt" -- Путь к файлу для сохранения максимальной энергии
totalReactorChambers = 0;

function ensureDirectoryExists(path)
    if path and not fs.isDirectory(path) then
            fs.makeDirectory(path)
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

function getPlayerMessage(playerName)
    for _, playerData in ipairs(playersData) do
        if playerData[1] == playerName then
            local message = playerData[3] or "Зашел в игру"
            if playerData[2] == "W" then
                message = "Зашла в игру"
            end
            return message
        end
    end
    return "Зашел в игру"
end

function getComponentsByType(componentType)
    local components = {}
    for address in component.list(componentType) do
        table.insert(components, { address = address})
    end
    return components
end

function countReactorChambers()
    local reactorChambers = component.list("reactor_chamber")
    local count = 0
    for _ in pairs(reactorChambers) do
        count = count + 1
    end
    return count
end

lastUpdateTime = 0
updateInterval = 3000
