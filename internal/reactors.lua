-- Author: https://github.com/Awl-S

local component = require("component")
local computer = require("computer")
local gui = require("sgui")
local utils = require("internal/utils")

local reactors = {}

local REACTOR_FILE = "/home/data/reactorInfo.txt"
local UPDATE_INTERVAL = 2
local TEMP_WARNING = 950
local MAX_REACTORS = 6

local lastUpdate = 0
local lastReactorCount = 0
local reactorsClearedOnce = false
local explosionNotified = false

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

local function getStats()
    local reactorsAddr = utils.getComponentsByType("htc_reactors_nuclear_reactor")
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

        gen = success2 and gen or 0
        mb = success3 and mb or 0
        t = success4 and t or 0
        hasWork = success5 and hasWork or false

        reactorsData[#reactorsData + 1] = {
            id = i,
            online = hasWork,
            energyGen = gen,
            coolant = mb,
            temp = t
        }

        totalEnergy = totalEnergy + gen
        totalCoolant = totalCoolant + mb
        hottest = math.max(hottest, t)

        ::continue::
    end

    return {
        reactors = reactorsData,
        count = #reactorsAddr,
        totalEnergy = totalEnergy,
        totalCoolant = totalCoolant,
        hottestTemp = hottest,
    }
end

local function notifyExplosion(missingCount, totalFound, maxExpected)
    local chatBox = component.isAvailable("chat_box") and component.chat_box
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
    chatBox.setName("§9§lОператор§7§o")
end

local function render(stats)
    local frames = require("main").frames or {reactors = {x = 2, y = 10, width = 116, height = 13}}
    local b = utils.getFrameInnerBounds(frames.reactors)
    local cols = 3
    local reactorWidth = math.floor(b.width / cols) - 1
    local reactorHeight = 4
    local separatorWidth = 1
    local clearWidth = 30
    
    if not reactorsClearedOnce or lastReactorCount ~= stats.count then
        for y = b.y, b.maxY do
            gui.text(b.x, y, string.rep(" ", clearWidth))
        end
        reactorsClearedOnce = true
        lastReactorCount = stats.count
    end
    
    for i = 1, math.min(6, #stats.reactors) do
        local reactor = stats.reactors[i]
        local colIndex = (i - 1) % cols
        local rowIndex = math.floor((i - 1) / cols)
        
        local x = b.x + colIndex * (reactorWidth + separatorWidth)
        local y = b.y + rowIndex * (reactorHeight + 1)
        
        local reactorColor = reactor.online and "&a" or "&4"
        local tempColor = reactor.temp >= TEMP_WARNING and "&c" or "&f"
        
        gui.text(x, y, reactorColor .. "Реактор №" .. reactor.id)
        gui.text(x, y + 1, "&fЭнергия: &6" .. formatReactorEnergy(reactor.energyGen))
        gui.text(x, y + 2, "&fРасход: &b" .. reactor.coolant .. " mB/s")
        gui.text(x, y + 3, "&fТемп: " .. tempColor .. reactor.temp .. "°C")
    end
    
    if stats.count > 0 then
        local summaryY = b.maxY
        gui.text(b.x, summaryY, string.rep(" ", clearWidth))
        gui.text(b.x, summaryY, string.format("&fΣ: &6%s &b%s mB/s &fРеакторов: &e%d", 
            formatReactorEnergy(stats.totalEnergy), stats.totalCoolant, stats.count))
    end
end

function reactors.update()
    local now = computer.uptime()
    if now - lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = now

    local stats = getStats()
    local maxStored = utils.loadFileData(REACTOR_FILE)

    if maxStored == 0 or stats.count > maxStored then
        maxStored = math.max(stats.count, MAX_REACTORS)
        utils.saveFileData(maxStored, REACTOR_FILE)
    end

    local missingReactors = maxStored - stats.count
    
    if stats.count < maxStored and missingReactors > 0 then
        if lastReactorCount ~= stats.count and lastReactorCount > 0 then
            explosionNotified = true
            notifyExplosion(missingReactors, stats.count, maxStored)
        end
    else
        if stats.count == maxStored then
            explosionNotified = false
        end
    end

    lastReactorCount = stats.count
    render(stats)
end

return reactors