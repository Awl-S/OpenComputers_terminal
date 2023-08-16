local component = require "component"
local computer = require "computer"

nameTable = "Рядовой Табуретка"
nameChat = "Рядовой Табуретка"

timerUpdate = 1200;
timerReactor = 100;
desiredTotalReactors = 50 -- Введите ваше количество реакторов

players = {
    -- игроки для проверки на онлайн {"ник", пол (M/W), сообщение, онлайн}
    {"Stawlie_", "M", "Царь батюшка на сервере", false},
    {"", "W", nil, false},
}
    
-------------------------------------------
--Информацию ниже лучше не редактировать
-------------------------------------------
W, H = 100, 48
colors = {0x525FE1, 0x525FE1, 0x525FE1, 0xEEE2DE}

local function energy(eu)
    if eu >= 1000000000 then
        return string.format("%.3f GEU/t", eu / 1000000000)
    elseif eu >= 1000000 then
        return string.format("%.3f MEU/t", eu / 1000000)
    else
        return string.format("%.3f kEU/t", eu / 1000)
    end
end

function getPlayerMessage(playerName)
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

---------Реакторы----------------
targetComponentType = "reactor_chamber"

-- Функция для проверки, работает ли реактор
function isReactorActive(reactorAddress)
    local reactor = component.proxy(reactorAddress)
    if reactor and reactor.getEUOutput then
      return reactor.getEUOutput() >= 1
    end
    return false
end

function getReactorEnergyProduction(reactorAddress)
    local reactor = component.proxy(reactorAddress)
    if reactor and reactor.getReactorEUOutput then
      return reactor.getReactorEUOutput()
    end
    return 0
  end

function debugReactor(nonWorkingReactors, nonWorkingID, chat)
if timerReactor == 100 then
    if nonWorkingReactors >= 1 then
        local nonWorkingMessage = "У вас не работают реактора: "
        for i, reactorID in ipairs(nonWorkingID) do
            if i > 1 then
                nonWorkingMessage = nonWorkingMessage .. ", "
            end
            nonWorkingMessage = nonWorkingMessage .. "#" .. reactorID
        end
        chat.say(nonWorkingMessage)
    end
end
end
