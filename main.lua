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
    
    if not targetFolder then
        targetFolder = findEnemyInstances()
    end
    
    if targetFolder then
        -- First, check direct children of the target folder
        for _, enemy in pairs(targetFolder:GetChildren()) do
            if enemy:IsA("Model") and (enemy:FindFirstChildOfClass("Humanoid") or enemy:FindFirstChild("HumanoidRootPart")) then
                -- Convert name to string to ensure it's not a table
                table.insert(names, tostring(enemy.Name))
            end
        end
        
        -- If no enemies found directly, search deeper
        if #names == 0 then
            for _, container in pairs(targetFolder:GetChildren()) do
                if container:IsA("Folder") or container:IsA("Model") then
                    for _, enemy in pairs(container:GetChildren()) do
                        if enemy:IsA("Model") and (enemy:FindFirstChildOfClass("Humanoid") or enemy:FindFirstChild("HumanoidRootPart")) then
                            -- Convert name to string to ensure it's not a table
                            table.insert(names, tostring(enemy.Name))
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

-- Function to find a specific enemy in the workspace
local function findEnemy(enemyName)
    -- Debug the enemy name we're looking for
    Rayfield:Notify({
        Title = "Debug Search",
        Content = "Looking for enemy: " .. tostring(enemyName),
        Duration = 2,
    })

    if not targetFolder then
        targetFolder = findEnemyInstances()
    end
    
    if not targetFolder then 
        Rayfield:Notify({
            Title = "Debug",
            Content = "Target folder not found",
            Duration = 3,
        })
        return nil 
    end
    
    -- Print the path to help debug
    Rayfield:Notify({
        Title = "Debug Path",
        Content = "Searching in: " .. targetFolder:GetFullName(),
        Duration = 2,
    })
    
    -- First check direct children
    local enemy = targetFolder:FindFirstChild(enemyName)
    if enemy and enemy:IsA("Model") then
        Rayfield:Notify({
            Title = "Debug",
            Content = "Enemy found directly: " .. tostring(enemyName),
            Duration = 1,
        })
        return enemy
    end
    
    -- If not found, try case-insensitive search
    for _, child in pairs(targetFolder:GetChildren()) do
        if child:IsA("Model") and string.lower(child.Name) == string.lower(enemyName) then
            Rayfield:Notify({
                Title = "Debug",
                Content = "Enemy found with case-insensitive match",
                Duration = 1,
            })
            return child
        end
    end
    
    -- If not found, search deeper
    for _, container in pairs(targetFolder:GetChildren()) do
        if container:IsA("Folder") or container:IsA("Model") then
            -- Try exact match
            enemy = container:FindFirstChild(enemyName)
            if enemy and enemy:IsA("Model") then
                Rayfield:Notify({
                    Title = "Debug",
                    Content = "Enemy found in container: " .. tostring(container.Name),
                    Duration = 1,
                })
                return enemy
            end
            
            -- Try case-insensitive match
            for _, child in pairs(container:GetChildren()) do
                if child:IsA("Model") and string.lower(child.Name) == string.lower(enemyName) then
                    Rayfield:Notify({
                        Title = "Debug",
                        Content = "Enemy found in container with case-insensitive match",
                        Duration = 1,
                    })
                    return child
                end
            end
        end
    end
    
    -- If still not found, try a more aggressive search with partial matching
    Rayfield:Notify({
        Title = "Debug",
        Content = "Trying aggressive search for: " .. tostring(enemyName),
        Duration = 1,
    })
    
    -- Try to find any model that contains the enemy name
    for _, obj in pairs(targetFolder:GetDescendants()) do
        if obj:IsA("Model") then
            -- Check if the model name contains our search term or vice versa
            if string.find(string.lower(obj.Name), string.lower(enemyName)) or 
               string.find(string.lower(enemyName), string.lower(obj.Name)) then
                Rayfield:Notify({
                    Title = "Debug",
                    Content = "Enemy found with partial match: " .. obj.Name,
                    Duration = 1,
                })
                return obj
            end
            
            -- Check if it has a humanoid (likely an enemy)
            if obj:FindFirstChildOfClass("Humanoid") then
                Rayfield:Notify({
                    Title = "Debug",
                    Content = "Found potential enemy with humanoid: " .. obj.Name,
                    Duration = 1,
                })
                -- Only return if we're desperate (no exact matches found)
                return obj
            end
        end
    end
    
    -- If still not found, search the entire workspace as a last resort
    local workspaceEnemy = workspace:FindFirstChild(enemyName, true)
    if workspaceEnemy then
        Rayfield:Notify({
            Title = "Debug",
            Content = "Enemy found in workspace",
            Duration = 1,
        })
        return workspaceEnemy
    end
    
    -- List all models in the target folder to help debug
    local modelNames = "Models in folder: "
    local count = 0
    for _, obj in pairs(targetFolder:GetChildren()) do
        if obj:IsA("Model") then
            modelNames = modelNames .. obj.Name .. ", "
            count = count + 1
            if count >= 5 then
                modelNames = modelNames .. "and more..."
                break
            end
        end
    end
    
    Rayfield:Notify({
        Title = "Debug Models",
        Content = modelNames,
        Duration = 3,
    })
    
    Rayfield:Notify({
        Title = "Debug",
        Content = "Enemy not found: " .. tostring(enemyName),
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
        -- Ensure Value is a string
        selectedEnemy = tostring(Value)
        if selectedEnemy == "No enemies found" then
            Rayfield:Notify({
                Title = "No Enemies Found",
                Content = "Try refreshing the list or join a game with enemies",
                Duration = 5,
            })
        else
            Rayfield:Notify({
                Title = "Enemy Selected",
                Content = "Selected: " .. tostring(selectedEnemy),
                Duration = 2,
            })
        end
    end,
})

-- Create a toggle for farming
local FarmingToggle = MainTab:CreateToggle({
    Name = "Auto Farm Enemies",
    CurrentValue = false,
    Flag = "FarmingToggle",
    Callback = function(Value)
        isFarming = Value
        if Value then
            if selectedEnemy and selectedEnemy ~= "No enemies found" then
                Rayfield:Notify({
                    Title = "Farming Started",
                    Content = "Now farming: " .. tostring(selectedEnemy),
                    Duration = 3,
                })
                -- Start farming loop
                spawn(function()
                    while isFarming and task.wait(0.1) do -- Small delay to prevent excessive teleporting
                        -- Farming logic goes here
                        local enemy = findEnemy(selectedEnemy)
                        if enemy and game.Players.LocalPlayer.Character then
                            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso") or enemy:FindFirstChild("UpperTorso") or enemy.PrimaryPart
                            local playerRoot = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            
                            if enemyRoot and playerRoot then
                                -- Debug teleport
                                Rayfield:Notify({
                                    Title = "Debug",
                                    Content = "Teleporting to enemy",
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
                                    
                                    -- Get the enemy's unique ID
                                    local enemyId = enemy:GetAttribute("Id") or enemy:GetAttribute("EnemyId") or enemy:GetAttribute("UniqueId")
                                    
                                    -- If we can't find an ID attribute, try to use the enemy's name or other identifiers
                                    if not enemyId then
                                        -- Try to find any attribute that might be an ID
                                        for _, attrName in pairs({"id", "ID", "uid", "UUID", "GUID"}) do
                                            if enemy:GetAttribute(attrName) then
                                                enemyId = enemy:GetAttribute(attrName)
                                                break
                                            end
                                        end
                                        
                                        -- If still no ID, use instance ID or name
                                        if not enemyId then
                                            enemyId = tostring(enemy:GetDebugId()) or enemy.Name
                                        end
                                    end
                                    
                                    -- Debug ID
                                    Rayfield:Notify({
                                        Title = "Debug",
                                        Content = "Using enemy ID: " .. tostring(enemyId),
                                        Duration = 1,
                                    })
                                    
                                    -- Fire the attack remote with the enemy ID
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
                end)
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

-- Initialize the farm distance
local farmDistance = 5

-- Auto-refresh enemy list periodically
spawn(function()
    while task.wait(30) do -- Refresh every 30 seconds
        refreshEnemyList()
    end
end)
