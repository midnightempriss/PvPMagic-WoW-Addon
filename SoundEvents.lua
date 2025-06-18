-- Sound Player for Events
-- Play a sound when the player kills another player in PvP
local function PlayKillSound()
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/KillMainSound.ogg", "Master")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_DEAD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_DEAD" then
        -- You can add logic here if you want to play a sound on your own death
        PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/DeathSound.ogg", "Master")
    end
end)

-- To detect killing another player in PvP, use COMBAT_LOG_EVENT_UNFILTERED
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
local function IsHostilePlayer(flags)
    return bit.band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
end

-- Killing blow streak tracker
local killingBlowStreak = 0

local function PlayStreakSound()
    -- You can use a different sound for streaks if you want
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/MultiKillSound.ogg", "Master")
end

combatFrame:SetScript("OnEvent", function()
    local _, subEvent, _, sourceGUID, _, _, _, destGUID, destName, destFlags, _, spellID = CombatLogGetCurrentEventInfo()
    if subEvent == "PARTY_KILL" and sourceGUID == UnitGUID("player") and IsHostilePlayer(destFlags) then
        killingBlowStreak = killingBlowStreak + 1
        if killingBlowStreak >= 2 then
            PlayStreakSound()
        else
            PlayKillSound()
        end
    end
end)

frame:HookScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_DEAD" then
        killingBlowStreak = 0
    end
end)

-- Start of a PvP match sound
local matchStartSoundPlayed = false

local function IsInPVPInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "pvp" or instanceType == "arena")
end

local function PlayMatchStartSound()
    if IsInPVPInstance() and not matchStartSoundPlayed then
        PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/MatchStartSound.ogg", "Master")
        matchStartSoundPlayed = true
    end
end

-- Ready check event
local f = CreateFrame("Frame")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("START_TIMER") -- This is used for match countdowns
f:RegisterEvent("PLAYER_ENTERING_WORLD") -- To reset the flag when leaving/entering instances

f:SetScript("OnEvent", function(self, event, ...)
    if event == "READY_CHECK" or event == "START_TIMER" then
        PlayMatchStartSound()
    elseif event == "PLAYER_ENTERING_WORLD" then
        matchStartSoundPlayed = false
    end
end)

-- Detect when a Warlock in your party or raid casts Create Soulwell and play a sound
local soulwellFrame = CreateFrame("Frame")
soulwellFrame:RegisterEvent("UNIT_SPELLCAST_START")

soulwellFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if event == "UNIT_SPELLCAST_START" and spellID == 29893 then -- 29893 = Create Soulwell
        if UnitInParty(unit) or UnitInRaid(unit) then
            local _, class = UnitClass(unit)
            if class == "WARLOCK" then
                -- Play sound
                PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/Warlock-Rocks.ogg", "Master")
            end
        end
    end
end)

-- Detect when a Mage in your party or raid casts Conjure Refreshment and play a sound
local refreshmentFrame = CreateFrame("Frame")
refreshmentFrame:RegisterEvent("UNIT_SPELLCAST_START")

refreshmentFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if event == "UNIT_SPELLCAST_START" and spellID == 190336 then -- 190336 = Conjure Refreshment
        if UnitInParty(unit) or UnitInRaid(unit) then
            local _, class = UnitClass(unit)
            if class == "MAGE" then
                -- Play sound (replace with your mage sound file if desired)
                PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/MageFoodSound.ogg", "Master")
            end
        end
    end
end)

-- Victory Sound Events
-- Play victory sound for duel wins and battleground victories

local victoryFrame = CreateFrame("Frame")
victoryFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
victoryFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE") 
victoryFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
victoryFrame:RegisterEvent("CHAT_MSG_SYSTEM")

local function PlayVictorySound()
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/VictorySound.ogg", "Master")
end

local function PlayDefeatSound()
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/DefeatedSound.ogg", "Master")
end

-- Track if we're in a duel to differentiate duel deaths from regular PvP deaths
local inDuel = false

victoryFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_SYSTEM" then
        local msg = ...
        local playerName = UnitName("player")
        
        -- Duel start detection
        if msg:find("duel") and msg:find("begin") then
            inDuel = true
        end
        
        -- Duel victory detection
        if msg:find(playerName .. " has defeated .* in a duel") then
            PlayVictorySound()
            inDuel = false
        end
        
        -- Duel defeat detection
        if msg:find(".* has defeated " .. playerName .. " in a duel") then
            PlayDefeatSound()
            inDuel = false
        end
          -- Duel ended (fled or cancelled)
        if msg:find("duel") and (msg:find("fled") or msg:find("cancelled")) then
            inDuel = false
        end
        
    elseif event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" or 
           event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or 
           event == "CHAT_MSG_BG_SYSTEM_HORDE" then
        local msg = ...
        
        -- Battleground victory/defeat detection
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then -- Only battlegrounds
            if msg:find("wins!") or msg:find("Victory!") or msg:find("has won") or msg:find("is victorious") then
                local myFaction = UnitFactionGroup("player")
                
                -- Check if our faction won
                if (myFaction == "Alliance" and (msg:find("Alliance") or msg:find("blue") or event == "CHAT_MSG_BG_SYSTEM_ALLIANCE")) or
                   (myFaction == "Horde" and (msg:find("Horde") or msg:find("red") or event == "CHAT_MSG_BG_SYSTEM_HORDE")) then
                    PlayVictorySound()
                else
                    -- If it's a victory message but not for our faction, we lost
                    PlayDefeatSound()
                end
            end
        end    end
end)

-- Hook player death event to play defeat sound for duel deaths
frame:HookScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_DEAD" then
        -- Only play defeat sound if we died in a duel (to avoid spamming in regular PvP)
        if inDuel then
            PlayDefeatSound()
        end
    end
end)

