local playersData = {
    {"Stawlie_", "Царь батюшка на сервере", false},
    {"Chomski", "Царь батюшка на сервере", false},
}

function getPlayerMessage(playerName)
    for _, playerData in ipairs(playersData) do
        if playerData[1] == playerName then
            local message = playerData[2] or "Зашел в игру"
            return message
        end
    end
    return "Зашел в игру"
end

local function processPlayersStatus()
    local playersStatus = {}
    local statusChanges = {}
    
    for i = 1, #playersData do
        computer.removeUser(playersData[i][1])
        if debugTest then
            computer.removeUser(debugTest)
        end
    end
    
    for i = 1, #playersData do
        local player = playersData[i][1]
        local isOnline = computer.addUser(player)
        local wasOnline = playersData[i][3]
        
        playersStatus[i] = {
            name = player,
            isOnline = isOnline,
            wasOnline = wasOnline,
            data = playersData[i]
        }
        
        if isOnline and not wasOnline then
            statusChanges[#statusChanges + 1] = {
                type = "joined",
                player = player,
                message = getPlayerMessage(player)
            }
            playersData[i][3] = true
        elseif not isOnline and wasOnline then
            statusChanges[#statusChanges + 1] = {
                type = "left",
                player = player
            }
            playersData[i][3] = false
        end
        
        if debugTest then
            computer.addUser(debugTest)
        end
        computer.addUser(playersData[i][1])
    end
    
    return {
        players = playersStatus,
        changes = statusChanges
    }
end

local function renderPlayersDisplay(processedData)
    local innerBounds = getFrameInnerBounds("players")
    
    local playerNameMaxLength = 20
    local maxColumns = math.floor(innerBounds.width / (playerNameMaxLength + 2))
    if maxColumns < 1 then maxColumns = 1 end
    
    local maxRowsPerColumn = innerBounds.height - 1
    local columnWidth = math.floor(innerBounds.width / maxColumns)
    
    local hasChanges = #processedData.changes > 0
    
    if hasChanges then
        local maxPlayers = maxColumns * maxRowsPerColumn
        
        for i = 1, maxPlayers do
            local columnIndex = (i - 1) % maxColumns
            local rowIndex = math.floor((i - 1) / maxColumns)
            
            if rowIndex < maxRowsPerColumn then
                local x = innerBounds.x + columnIndex * columnWidth
                local y = innerBounds.y + 1 + rowIndex
                
                if x <= innerBounds.maxX - playerNameMaxLength and y <= innerBounds.maxY then
                    gui.text(x, y, string.rep(" ", math.min(columnWidth - 1, playerNameMaxLength)))
                end
            end
        end
        
        for i = 1, #processedData.players do
            local playerInfo = processedData.players[i]
            
            local columnIndex = (i - 1) % maxColumns
            local rowIndex = math.floor((i - 1) / maxColumns)
            
            if rowIndex < maxRowsPerColumn then
                local x = innerBounds.x + columnIndex * columnWidth
                local y = innerBounds.y + 1 + rowIndex
                
                if x <= innerBounds.maxX - playerNameMaxLength and y <= innerBounds.maxY then
                    local prefix = ""
                    if playerInfo.isOnline then
                        prefix = "&2"
                    else
                        prefix = "&4"
                    end
                    prefix = prefix .. playerInfo.name
                    gui.text(x, y, prefix)
                end
            end
        end
    end
end

local function handleChatMessages(statusChanges)
    if not chatBox then return end
    
    for i = 1, #statusChanges do
        local change = statusChanges[i]
        if change.type == "joined" then
            chatBox.say("§e" .. change.player .. "§a§l " .. change.message)
        elseif change.type == "left" then
            chatBox.say("§e" .. change.player .. "§c§l покинул игру!")
        end
    end
end
