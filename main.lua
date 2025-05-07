local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Arise Learning",
    LoadingTitle = "Arise Learning",
    LoadingSubtitle = "by Nisul",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "AriseLearning",
       FileName = "AriseLearning"
    },
    Discord = {
       Enabled = false,
       Invite = "discord-invite-here",
       RememberJoins = true
    },
    KeySystem = false, 
    KeySettings = {
       Title = "Key System",
       Subtitle = "Key Required",
       Note = "Enter the key to access the script",
       FileName = "Key",
       SaveKey = true,
       GrabKeyFromSite = false,
       Key = {"Example"}
    }
 })
 
-- Variables for farming
local selectedEnemy = nil
local isFarming = false
local mainFolder = workspace:FindFirstChild("__Main") -- First find the __Main folder
local enemyFolder = mainFolder and mainFolder:FindFirstChild("__Enemies") -- Then find __Enemies inside __Main
local enemyNames = {"No enemies found"} -- Default value
local targetFolder = nil -- Will store the actual folder containing enemy instances (Server or direct)
local enemyModels = {} -- Store enemy models by their index in the dropdown
local currentFarmingLoop = nil -- Reference to the current farming loop
local farmDistance = 5 -- Initialize the farm distance

-- Function to find actual enemy instances
local function findEnemyInstances()
    -- First, find the __Main folder
    if not mainFolder then
        mainFolder = workspace:FindFirstChild("__Main")
    end
    
    -- Then find the __Enemies folder inside __Main
    if mainFolder and not enemyFolder then
        enemyFolder = mainFolder:FindFirstChild("__Enemies")
    end
    
    -- If we still don't have the enemy folder, try to find it directly or search for alternatives
    if not enemyFolder then
        -- Try direct path first
        enemyFolder = workspace:FindFirstChild("__Enemies")
        
        -- If still not found, try to find any enemy-related folder as fallback
        if not enemyFolder then
            -- Check in __Main first if it exists
            if mainFolder then
                for _, child in pairs(mainFolder:GetChildren()) do
                    if child.Name:lower():find("enem") or child.Name:lower():find("mob") then
                        enemyFolder = child
                        break
                    end
                end
            end
            
            -- If still not found, check workspace
            if not enemyFolder then
                for _, child in pairs(workspace:GetChildren()) do
                    if child.Name:lower():find("enem") or child.Name:lower():find("mob") then
                        enemyFolder = child
                        break
                    end
                end
            end
        end
    end
    
    if not enemyFolder then return nil end
    
    -- Check if Client folder exists within the enemy folder (prioritize Client over Server)
    local clientFolder = enemyFolder:FindFirstChild("Client")
    if clientFolder then
        return clientFolder
    end
    
    -- If no Client folder, check for Server folder as fallback
    local serverFolder = enemyFolder:FindFirstChild("Server")
    if serverFolder then
        return serverFolder
    end
    
    -- If no specific subfolder has enemies, use the main enemy folder
    return enemyFolder
end

-- Function to get all enemy names
local function getEnemyNames()
    local names = {}
    enemyModels = {} -- Reset the enemy models table
    
    if not targetFolder then
        targetFolder = findEnemyInstances()
    end
    
    if targetFolder then
        -- First, check direct children of the target folder
        for _, enemy in pairs(targetFolder:GetChildren()) do
            if enemy:IsA("Model") and (enemy:FindFirstChildOfClass("Humanoid") or enemy:FindFirstChild("HumanoidRootPart")) then
                -- Store the actual model reference
                table.insert(enemyModels, enemy)
                -- Use index as identifier and enemy name as display
                table.insert(names, "#" .. #enemyModels .. ": " .. tostring(enemy.Name))
            end
        end
        
        -- If no enemies found directly, search deeper
        if #names == 0 then
            for _, container in pairs(targetFolder:GetChildren()) do
                if container:IsA("Folder") or container:IsA("Model") then
                    for _, enemy in pairs(container:GetChildren()) do
                        if enemy:IsA("Model") and (enemy:FindFirstChildOfClass("Humanoid") or enemy:FindFirstChild("HumanoidRootPart")) then
                            -- Store the actual model reference
                            table.insert(enemyModels, enemy)
                            -- Use index as identifier and enemy name as display
                            table.insert(names, "#" .. #enemyModels .. ": " .. tostring(enemy.Name))
                        end
                    end
                end
            end
        end
    end
    
    if #names == 0 then
        return {"No enemies found"}
    end
    
    table.sort(names) -- Sort alphabetically for easier selection
    return names
end

-- Function to find a specific enemy by dropdown selection
local function findEnemy(selection)
    -- Debug the selection
    Rayfield:Notify({
        Title = "Debug Selection",
        Content = "Type: " .. type(selection) .. ", Value: " .. tostring(selection),
        Duration = 2,
    })

    -- Try to find the index in the enemyModels array
    for index, model in ipairs(enemyModels) do
        local indexString = "#" .. index .. ":"
        
        -- Check if the selection string contains our index pattern
        if type(selection) == "string" and selection:find(indexString) then
            Rayfield:Notify({
                Title = "Debug",
                Content = "Enemy found by pattern match: " .. tostring(model.Name),
                Duration = 1,
            })
            return model
        end
    end
    
    -- If we couldn't find by pattern, try to use the selection directly as an index
    local directIndex = nil
    
    -- If selection is a number, use it directly
    if type(selection) == "number" then
        directIndex = selection
    -- If it's a string that might be a number, convert it
    elseif type(selection) == "string" then
        directIndex = tonumber(selection:match("(%d+)"))
    end
    
    if directIndex and enemyModels[directIndex] then
        Rayfield:Notify({
            Title = "Debug",
            Content = "Enemy found by direct index: " .. directIndex,
            Duration = 1,
        })
        return enemyModels[directIndex]
    end
    
    -- Last resort: if we have only one enemy, return it
    if #enemyModels == 1 then
        Rayfield:Notify({
            Title = "Debug",
            Content = "Using only available enemy as fallback",
            Duration = 1,
        })
        return enemyModels[1]
    end
    
    Rayfield:Notify({
        Title = "Debug",
        Content = "Enemy not found for selection: " .. tostring(selection),
        Duration = 3,
    })
    return nil
end

-- Function to refresh the enemy list
local function refreshEnemyList()
    enemyNames = getEnemyNames()
    
    -- Update the dropdown with new enemy names
    if EnemyDropdown then
        EnemyDropdown:Refresh(enemyNames, (selectedEnemy and table.find(enemyNames, selectedEnemy)) and selectedEnemy or enemyNames[1])
    end
end

-- Create a tab
local MainTab = Window:CreateTab("Main test farm")

-- Create a section for enemy selection
local FarmingSection = MainTab:CreateSection("Enemy Farming")

-- Create a button to refresh the enemy list
local RefreshButton = MainTab:CreateButton({
    Name = "Refresh Enemy List",
    Callback = function()
        targetFolder = findEnemyInstances() -- Re-find the target folder
        refreshEnemyList()
        Rayfield:Notify({
            Title = "Enemy List Refreshed",
            Content = #enemyNames .. " enemies found" .. (targetFolder and (" in " .. targetFolder.Name) or ""),
            Duration = 3,
        })
    end,
})

-- Initial enemy list population
refreshEnemyList()

-- Create a dropdown for enemy selection
local EnemyDropdown = MainTab:CreateDropdown({
    Name = "Select Enemy to Farm",
    Options = enemyNames,
    CurrentOption = enemyNames[1],
    Flag = "EnemyToFarm",
    Callback = function(Value)
        -- Store the selection directly without conversion
        local oldEnemy = selectedEnemy
        
        -- Debug the value type
        Rayfield:Notify({
            Title = "Debug Value",
            Content = "Type: " .. type(Value) .. ", Value: " .. tostring(Value),
            Duration = 2,
        })
        
        if tostring(Value) == "No enemies found" then
            Rayfield:Notify({
                Title = "No Enemies Found",
                Content = "Try refreshing the list or join a game with enemies",
                Duration = 5,
            })
            return
        else
            -- Store the index of the selected enemy
            local selectedIndex = 1
            for i, name in ipairs(enemyNames) do
                if tostring(Value) == tostring(name) then
                    selectedIndex = i
                    break
                end
            end
            
            Rayfield:Notify({
                Title = "Enemy Selected",
                Content = "Selected index: " .. selectedIndex,
                Duration = 2,
            })
            
            -- Store the index instead of the name
            selectedEnemy = selectedIndex
            
            -- If already farming, update the target without restarting the loop
            if isFarming and oldEnemy ~= selectedEnemy then
                Rayfield:Notify({
                    Title = "Target Updated",
                    Content = "Now targeting: " .. tostring(enemyNames[selectedIndex]),
                    Duration = 2,
                })
            end
        end
    end,
})

-- Function to start the farming loop
local function startFarmingLoop()
    -- If there's already a farming loop running, don't start another one
    if currentFarmingLoop then return end
    
    -- Create a new farming loop
    currentFarmingLoop = spawn(function()
        while isFarming and task.wait(0.1) do -- Small delay to prevent excessive teleporting
            -- Get the enemy directly from the array if we have an index
            local enemy = nil
            if type(selectedEnemy) == "number" and enemyModels[selectedEnemy] then
                enemy = enemyModels[selectedEnemy]
            else
                enemy = findEnemy(selectedEnemy)
            end
            
            if enemy and game.Players.LocalPlayer.Character then
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso") or enemy:FindFirstChild("UpperTorso") or enemy.PrimaryPart
                local playerRoot = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if enemyRoot and playerRoot then
                    -- Debug teleport
                    Rayfield:Notify({
                        Title = "Debug",
                        Content = "Teleporting to enemy: " .. enemy.Name,
                        Duration = 1,
                    })
                    
                    -- Try to teleport using different methods
                    pcall(function()
                        -- Method 1: Direct CFrame assignment
                        playerRoot.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, farmDistance)
                    end)
                    
                    -- Auto attack using the provided remote
                    local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        -- Face the enemy
                        humanoid.AutoRotate = false
                        playerRoot.CFrame = CFrame.lookAt(playerRoot.Position, enemyRoot.Position)
                        
                        -- Get the enemy's unique ID - use the raw name as the ID
                        local enemyId = enemy.Name
                        
                        -- Debug ID
                        Rayfield:Notify({
                            Title = "Debug",
                            Content = "Using enemy ID: " .. tostring(enemyId),
                            Duration = 1,
                        })
                        
                        -- Fire the attack remote with the raw enemy ID
                        local args = {
                            {
                                {
                                    Event = "PunchAttack",
                                    Enemy = enemyId
                                },
                                "\005"
                            }
                        }
                        
                        pcall(function()
                            game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
                        end)
                        
                        -- Add a small delay to prevent spamming the remote too quickly
                        task.wait(0.1)
                    else
                        Rayfield:Notify({
                            Title = "Debug",
                            Content = "Humanoid not found",
                            Duration = 1,
                        })
                    end
                else
                    Rayfield:Notify({
                        Title = "Debug",
                        Content = enemyRoot and "Player root not found" or "Enemy root not found",
                        Duration = 1,
                    })
                end
            else
                Rayfield:Notify({
                    Title = "Debug",
                    Content = enemy and "Player character not found" or "Enemy not found",
                    Duration = 1,
                })
            end
        end
        
        -- Reset auto-rotate when farming stops
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").AutoRotate = true
        end
        
        -- Clear the reference to the farming loop
        currentFarmingLoop = nil
    end)
end

-- Create a toggle for farming
local FarmingToggle = MainTab:CreateToggle({
    Name = "Auto Farm Enemies",
    CurrentValue = false,
    Flag = "FarmingToggle",
    Callback = function(Value)
        isFarming = Value
        if Value then
            if selectedEnemy and selectedEnemy ~= "No enemies found" then
                local selectedEnemyName = type(selectedEnemy) == "number" and 
                                         (enemyNames[selectedEnemy] or "Unknown") or 
                                         tostring(selectedEnemy)
                
                Rayfield:Notify({
                    Title = "Farming Started",
                    Content = "Now farming: " .. selectedEnemyName,
                    Duration = 3,
                })
                
                -- Start the farming loop
                startFarmingLoop()
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please select a valid enemy first",
                    Duration = 3,
                })
                FarmingToggle:Set(false)
            end
        else
            Rayfield:Notify({
                Title = "Farming Stopped",
                Content = "Auto farming has been disabled",
                Duration = 3,
            })
        end
    end,
})

-- Create a slider for teleport distance
local DistanceSlider = MainTab:CreateSlider({
    Name = "Farm Distance",
    Range = {2, 15},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 5,
    Flag = "FarmDistance",
    Callback = function(Value)
        -- This value will be used in the farming loop
        farmDistance = Value
    end,
})

-- Auto-refresh enemy list periodically
spawn(function()
    while task.wait(30) do -- Refresh every 30 seconds
        refreshEnemyList()
    end
end)
