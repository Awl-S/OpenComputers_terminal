local component = require("component")
local gui = require("sgui")
local utils = require("internal/utils")

local energy = {}

local MAX_ENERGY_FILE = "/home/data/energyInfo.txt"
local maxEnergyFluxNetwork = utils.loadFileData(MAX_ENERGY_FILE)

local function getFluxComponent()
    local fluxComponentNames = {"flux_network", "fluxnetwork", "flux_controller", "fluxnetworks", "flux_plug"}
    
    for _, name in ipairs(fluxComponentNames) do
        if component.isAvailable(name) then
            return component[name]
        end
    end
    return nil
end

function energy.getFluxNetworkStats()
    local flux = getFluxComponent()
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
        utils.saveFileData(maxEnergyFluxNetwork, MAX_ENERGY_FILE)
    end

    return {
        name = nfo.name or "Unknown Network",
        input = e.energyInput or 0,
        buffer = e.totalBuffer or 0,
        maxInput = maxEnergyFluxNetwork
    }
end

function energy.render(stats)
    if not stats then
        gui.text(3, 4, "&cFlux Network: Error")
        return
    end
    
    gui.text(3, 5, string.rep(" ", 20))
    gui.text(3, 4, "&aСеть:&e " .. tostring(stats.name))

    gui.text(3, 5, string.rep(" ", 20))
    gui.text(3, 5, "&aВход: &2" .. utils.formatEnergy(stats.input / 4))

    gui.text(3, 6, string.rep(" ", 20))
    gui.text(3, 6, "&aБуфер:&2 " .. string.sub(utils.formatEnergy(stats.buffer), 1, -3))

    gui.text(3, 7, "&aМаксимальный вход:&2 " .. utils.formatEnergy(stats.maxInput / 4))
end

return energy