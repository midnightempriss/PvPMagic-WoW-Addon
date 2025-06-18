-- This part of the code is a welcome message that greets the player and tells them their current PvP Honor level. 
-- Moved to run on PLAYER_LOGIN event instead of immediately

-- This part of the code is a complementary part of the login message that will only play on player login it plays a welcome sound file.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")

local hasPlayed = false
local hasShownMessage = false

frame:SetScript("OnEvent", function(self, event, isLogin, isReload)
    if event == "PLAYER_ENTERING_WORLD" and isLogin and not hasPlayed then
        PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/WelcomeEventSound.ogg", "Master")
        hasPlayed = true
    elseif event == "PLAYER_LOGIN" and not hasShownMessage then
        DEFAULT_CHAT_FRAME:AddMessage("Welcome, " .. UnitName("player") .. "! Your current PvP Honor level is: " .. UnitHonorLevel("player") .. " Are you ready to conquer Azeroth and crack some skulls today? Lok'tar ogar! Victory or death, friend!")
        hasShownMessage = true
    end
end)

-- Centralized slash command handler
local function HandlePvPMagicCommand(msg)
    if not msg then msg = "" end
    local args = {strsplit(" ", msg:lower())}
    local command = args[1]
    
    if command == "wt" then
        DEFAULT_CHAT_FRAME:AddMessage("Welcome, " .. UnitName("player") .. ". Your current PvP Honor level is: " .. UnitHonorLevel("player") .. " Are you ready to conquer Azeroth and crack some skulls today? Lok'tar ogar! Victory or death, friend!")
    elseif command == "tcall" then
        -- This will be handled by the target caller module
        return false
    else
        DEFAULT_CHAT_FRAME:AddMessage("[PvPMagic] Available commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /pvpmagic wt - Show welcome message")
        DEFAULT_CHAT_FRAME:AddMessage("  /pvpmagic tcall - Toggle target caller")
    end
    return true
end

-- Register slash command
SLASH_PVPMAGIC1 = "/pvpmagic"
SlashCmdList["PVPMAGIC"] = HandlePvPMagicCommand