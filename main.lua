-- Author: https://github.com/Awl-S
local component = require("component")
local computer = require("computer")
local term = require("term")

local gui = require("sgui")
local utils = require("internal/utils")
local energy = require("internal/energy")
local players = require("internal/players")
local reactors = require("internal/reactors")
local mecontroller = require("internal/mecontroller")

local SCREEN_WIDTH, SCREEN_HEIGHT = 120, 40
local UPDATE_INTERVAL = 0.1

local frames = {
    energy = {x = 2, y = 2, width = 34, height = 8, title = "Энерго-сеть"},
    players = {x = 38, y = 2, width = 0, height = 8, title = "Игроки"},
    reactors = {x = 2, y = 10, width = 0, height = 13, title = "Реакторы"},
    meProcesses = {x = 2, y = 23, width = 0, height = 17, title = "МЭ Процессы создания"},
}

local function calculateFrameSizes()
    frames.players.width = SCREEN_WIDTH - frames.players.x
    frames.reactors.width = SCREEN_WIDTH - frames.reactors.x
    frames.meProcesses.width = SCREEN_WIDTH - frames.meProcesses.x
end

local function initializeInterface()
    term.clear()
    
    local gpu = component.isAvailable("gpu") and component.gpu
    if not gpu then
        error("GPU component not available")
    end
    
    gpu.setResolution(SCREEN_WIDTH, SCREEN_HEIGHT)
    calculateFrameSizes()
    
    gui.drawMain("&d[Мониторинг]", gui.colors["border"], "2.0")
    gui.drawFrame(frames.energy.x, frames.energy.y, frames.energy.width, frames.energy.height, frames.energy.title, gui.colors["border"])
    gui.drawFrame(frames.players.x, frames.players.y, frames.players.width, frames.players.height, frames.players.title, gui.colors["border"])
    gui.drawFrame(frames.reactors.x, frames.reactors.y, frames.reactors.width, frames.reactors.height, frames.reactors.title, gui.colors["border"])
    gui.drawFrame(frames.meProcesses.x, frames.meProcesses.y, frames.meProcesses.width, frames.meProcesses.height, frames.meProcesses.title, gui.colors["border"])
end

local function mainLoop()
    while true do
        local meData = mecontroller.getStats()
        local playersData = players.processStatus()
        local energyStats = energy.getFluxNetworkStats()
        
        mecontroller.render(meData, utils.getFrameInnerBounds(frames.meProcesses))
        players.render(playersData, utils.getFrameInnerBounds(frames.players))
        energy.render(energyStats)
        reactors.update(frames)
        
        players.handleChatMessages(playersData.changes)
        
        computer.pullSignal(UPDATE_INTERVAL)
    end
end

local function main()
    initializeInterface()
    
    local chatBox = component.isAvailable("chat_box") and component.chat_box
    if chatBox then
        chatBox.setName("§9§lОператор§7§o")
    end
    
    mainLoop()
end

return {
    frames = frames,
    main = main
}