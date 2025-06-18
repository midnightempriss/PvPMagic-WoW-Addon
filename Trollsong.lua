-- Troll song player that roastes the player and encourages them to do better in PvP.
local pvpDeathCount = 0
local PVP_SOUND_PATH = "Interface/AddOns/PvPMagic/Media/Sounds/TrollSong-YouSuck.ogg"
local PVP_SOUND_CHANNEL = "Master"

local function IsInPVPZone()
    local inInstance, instanceType = IsInInstance()
    return (inInstance and (instanceType == "pvp" or instanceType == "arena"))
end

local pvpFrame = CreateFrame("Frame")
pvpFrame:RegisterEvent("PLAYER_DEAD")
pvpFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pvpFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

pvpFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        pvpDeathCount = 0
    elseif event == "PLAYER_DEAD" then
        if IsInPVPZone() then
            pvpDeathCount = pvpDeathCount + 1
            DEFAULT_CHAT_FRAME:AddMessage("[PvPMagic] PvP Deaths: " .. pvpDeathCount)
            if pvpDeathCount == 5 then
                PlaySoundFile(PVP_SOUND_PATH, PVP_SOUND_CHANNEL)
                DEFAULT_CHAT_FRAME:AddMessage("[PvPMagic] Played sound for 5 deaths in PvP.")
            end
        else
            pvpDeathCount = 0
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        if subEvent == "PARTY_KILL" and sourceGUID == UnitGUID("player") and IsInPVPZone() then
            pvpDeathCount = 0
            DEFAULT_CHAT_FRAME:AddMessage("[PvPMagic] Killing blow detected, counter reset.")
        end
    end
end)