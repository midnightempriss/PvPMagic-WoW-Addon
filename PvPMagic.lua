-- This part of the code is a welcome message that greats the player and tells them thier current PvP Honor level. 
DEFAULT_CHAT_FRAME:AddMessage("Welcome, " .. UnitName("player") .. "! Your current PvP Honor level is: " .. UnitHonorLevel("player") .. " Are you ready to conquer Azeroth and crack some skulls today? Lok'tar ogar! Victory or death, friend!")

-- Register slash command to fire the welcome message on demand.
SLASH_PVPMAGIC1 = "/pvpmagic"

SlashCmdList["PVPMAGIC"] = function(msg)
    if msg == "wt" then
        DEFAULT_CHAT_FRAME:AddMessage("Welcome, " .. UnitName("player") .. ". Your current PvP Honor level is: " .. UnitHonorLevel("player") .. " Are you ready to conquer Azeroth and crack some skulls today? Lok'tar ogar! Victory or death, friend!")
    end
end