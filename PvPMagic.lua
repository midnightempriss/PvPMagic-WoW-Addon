-- This part of the code is a welcome message that greats the player and tells them thier current PvP Honor level. 
DEFAULT_CHAT_FRAME:AddMessage("Welcome, " .. UnitName("player") .. "! Your current PvP Honor level is: " .. UnitHonorLevel("player") .. " Are you ready to conquer Azeroth and crack some skulls today? Lok'tar ogar! Victory or death, friend!")
-- This part of the code is a complemtary part of the login message that will only play on player login it plays a welcome sound file.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local hasPlayed = false

frame:SetScript("OnEvent", function(self, event, isLogin, isReload)
    if event == "PLAYER_ENTERING_WORLD" and isLogin and not hasPlayed then
        PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/WelcomeEventSound.ogg", "Master")
        hasPlayed = true
    end
end)

-- Register slash command to fire the welcome message on demand.
SLASH_PVPMAGIC1 = "/pvpmagic"

SlashCmdList["PVPMAGIC"] = function(msg)
    if msg == "wt" then
        DEFAULT_CHAT_FRAME:AddMessage("Welcome, " .. UnitName("player") .. ". Your current PvP Honor level is: " .. UnitHonorLevel("player") .. " Are you ready to conquer Azeroth and crack some skulls today? Lok'tar ogar! Victory or death, friend!")
    end
end

-- Sound Player for Events
-- Play a sound when the player kills another player in PvP or wins a duel
local function PlayKillOrDuelWinSound()
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/KillMainSound.ogg", "Master")
end

local function PlayKillSound()
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/KillMainSound.ogg", "Master")
end

local function PlayDuelWinSound()
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/KillMainSound.ogg", "Master")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_SYSTEM")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_SYSTEM" then
        local msg = ...
        -- Try to match the duel win message pattern (case-insensitive, locale-agnostic)
        local playerName = UnitName("player")
        if msg:lower():find(playerName:lower() .. " has defeated ") and msg:lower():find("in a duel") then
            PlayDuelWinSound()
        end
    elseif event == "PLAYER_DEAD" then
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

-- Target Calling and Toggle for focus callout
local PvPMagic_FocusCallEnabled = true

local function AlertFocusTarget()
    if not PvPMagic_FocusCallEnabled then return end
    if not UnitExists("focus") then return end
    SetRaidTarget("focus", 8)
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/KillFocusSound.ogg", "Master")
    local name = UnitName("focus")
    local msg = "Let's target and kill " .. name .. " group up for the kill!"
    if IsInRaid() then
        SendChatMessage(msg, "RAID")
    elseif IsInGroup() then
        SendChatMessage(msg, "PARTY")
    end
end

-- Add /pvpmagic tcall toggle command
SLASH_PVPMAGICTCALL1 = "/pvpmagic"
local origPvPMagicHandler = SlashCmdList["PVPMAGIC"]
SlashCmdList["PVPMAGIC"] = function(msg)
    if msg and msg:lower():find("tcall") then
        PvPMagic_FocusCallEnabled = not PvPMagic_FocusCallEnabled
        local state = PvPMagic_FocusCallEnabled and "ON" or "OFF"
        DEFAULT_CHAT_FRAME:AddMessage("[PvPMagic] Focus callout is now: " .. state)
    else
        if origPvPMagicHandler then origPvPMagicHandler(msg) end
    end
end

-- Automatically call AlertFocusTarget on focus set/change
local focusFrame = CreateFrame("Frame")
focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusFrame:SetScript("OnEvent", function()
    AlertFocusTarget()
end)

-- Remove raid marker when focus is cleared
local clearFocusFrame = CreateFrame("Frame")
clearFocusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
clearFocusFrame:SetScript("OnEvent", function()
    if not UnitExists("focus") then
        -- Remove all raid markers from previous focus
        for i = 1, 8 do
            SetRaidTarget("focus", 0)
        end
    end
end)

-- Track and clear raid marker from previous focus
local lastFocusGUID = nil
local function ClearRaidMarkerFromGUID(guid)
    if not guid then return end
    for i = 1, 40 do
        local unit = "nameplate"..i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            SetRaidTarget(unit, 0)
            break
        end
    end
    for i = 1, 4 do
        local unit = "party"..i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            SetRaidTarget(unit, 0)
            break
        end
    end
    for i = 1, 40 do
        local unit = "raid"..i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            SetRaidTarget(unit, 0)
            break
        end
    end
end

local focusChangeFrame = CreateFrame("Frame")
focusChangeFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusChangeFrame:SetScript("OnEvent", function()
    if not UnitExists("focus") and lastFocusGUID then
        ClearRaidMarkerFromGUID(lastFocusGUID)
        lastFocusGUID = nil
    elseif UnitExists("focus") then
        lastFocusGUID = UnitGUID("focus")
    end
end)

-- Function to create a macro for focus callout
local function CreateFocusCallMacro()
    local macroName = "FocusCall"
    local macroIcon = "INV_Misc_QuestionMark"
    local macroBody = "/focus target\n/ping [@focus] attack"
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then
        if GetNumMacros() < MAX_ACCOUNT_MACROS then
            CreateMacro(macroName, macroIcon, macroBody, false)
            print("[PvPMagic] Macro 'FocusCall' created!")
        else
            print("[PvPMagic] Cannot create macro: macro limit reached.")
        end
    else
        print("[PvPMagic] Macro 'FocusCall' already exists.")
    end
end

-- Create the macro on login (out of combat only)
local macroFrame = CreateFrame("Frame")
macroFrame:RegisterEvent("PLAYER_LOGIN")
macroFrame:SetScript("OnEvent", function()
    if InCombatLockdown() then
        macroFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        CreateFocusCallMacro()
    end
end)
macroFrame:HookScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        CreateFocusCallMacro()
        macroFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end)

-- Example: call AlertFocusTarget() from a keybind, macro, or other event
-- AlertFocusTarget()

