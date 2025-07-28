local component = require("component")
local computer = require("computer")
local term = require("term")
local event = require("event")
local thread = require("thread")
local filesystem = require("filesystem")

local gui = require("sgui")
local ae_lib = require("applied_energistics")

local utils = {}

function utils.removeFile(filepath)
    return os.remove(filepath)
end

function utils.ensureDirectoryExists(path)
    if not filesystem.exists(path) then
        filesystem.makeDirectory(path)
    end
end

local gpu = component.isAvailable("gpu") and component.gpu or nil
local chatBox = component.isAvailable("chat_box") and component.chat_box or nil

local screenWidth, screenHeight = 120, 40

local frames = {
    meProcesses = {x = 2, y = 2, width = screenWidth - 2, height = screenHeight - 2, title = "МЭ Процессы создания"},
}

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

local function initialize()
    ae_lib.init({
        component = component,
        gui = gui,
        utils = utils,
        computer = computer
    })
    
    if gpu then
        gpu.setResolution(screenWidth, screenHeight)
        term.clear()
        
        gui.drawMain("&dME Мониторинг", gui.colors["border"], "2")
        gui.drawFrame(
            frames.meProcesses.x, 
            frames.meProcesses.y, 
            frames.meProcesses.width, 
            frames.meProcesses.height, 
            frames.meProcesses.title, 
            gui.colors["border"]
        )
    end
    
    if chatBox then
        chatBox.setName("§9§lME Оператор§7§o")
    end
    
end

local function mainLoop()
    while true do
        local meData = ae_lib.getData()
        local bounds = getFrameInnerBounds("meProcesses")
        ae_lib.render(meData, bounds)
        computer.pullSignal(0.1)
    end
end

local function safeMain()
    local success, error = pcall(function()
        initialize()
        mainLoop()
    end)
    
    if not success then
        if chatBox then
            chatBox.say("§cКритическая ошибка: " .. tostring(error))
        end
        
        if gpu then
            term.clear()
            print("Критическая ошибка:")
            print(tostring(error))
            print("Нажмите любую клавишу для перезагрузки...")
            io.read()
            computer.shutdown(true)
        end
    end
end

safeMain()