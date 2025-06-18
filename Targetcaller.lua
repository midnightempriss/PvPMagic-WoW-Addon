-- Target Calling and Toggle for focus callout
local PvPMagic_FocusCallEnabled = true

local function AlertFocusTarget()
    if not PvPMagic_FocusCallEnabled then return end
    if not UnitExists("focus") then return end
    SetRaidTarget("focus", 8)
    PlaySoundFile("Interface/AddOns/PvPMagic/Media/Sounds/KillFocusSound.ogg", "Master")
    local name = UnitName("focus")
    local msg = "Let's target and kill " .. name .. " group up for the kill!"
    
    -- Check if in a PvP instance (battleground/arena) and use instance chat
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        SendChatMessage(msg, "INSTANCE_CHAT")
    elseif IsInRaid() then
        SendChatMessage(msg, "RAID")
    elseif IsInGroup() then
        SendChatMessage(msg, "PARTY")
    end
end

-- Add /pvpmagic tcall toggle command
local function HandleTCallCommand()
    PvPMagic_FocusCallEnabled = not PvPMagic_FocusCallEnabled
    local state = PvPMagic_FocusCallEnabled and "ON" or "OFF"
    DEFAULT_CHAT_FRAME:AddMessage("[PvPMagic] Focus callout is now: " .. state)
end

-- Hook into the main slash command system
local originalHandler = SlashCmdList["PVPMAGIC"]
if originalHandler then
    SlashCmdList["PVPMAGIC"] = function(msg)
        if not msg then msg = "" end
        local args = {strsplit(" ", msg:lower())}
        local command = args[1]
        
        if command == "tcall" then
            HandleTCallCommand()
        else
            -- Pass to original handler
            originalHandler(msg)
        end
    end
else
    -- Fallback if no original handler exists
    SLASH_PVPMAGIC1 = "/pvpmagic"
    SlashCmdList["PVPMAGIC"] = function(msg)
        if not msg then msg = "" end
        local args = {strsplit(" ", msg:lower())}
        local command = args[1]
        
        if command == "tcall" then
            HandleTCallCommand()
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PvPMagic] Available commands:")
            DEFAULT_CHAT_FRAME:AddMessage("  /pvpmagic tcall - Toggle target caller")
        end
    end
end

-- Automatically call AlertFocusTarget on focus set/change
local focusFrame = CreateFrame("Frame")
focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusFrame:SetScript("OnEvent", function()
    AlertFocusTarget()
end)

-- Remove raid marker when focus is cleared - Fixed version
local clearFocusFrame = CreateFrame("Frame")
clearFocusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
clearFocusFrame:SetScript("OnEvent", function()
    -- This is handled by the focusChangeFrame below with proper GUID tracking
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
local function CreatePvPMagicTCMacro()
    local macroName = "PvPMagic TC"
    local macroIcon = "Ability_DualWield"
    local macroBody = "/focus target\n/ping [@focus] attack"
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then
        if GetNumMacros() < MAX_ACCOUNT_MACROS then
            CreateMacro(macroName, macroIcon, macroBody, false)
            print("[PvPMagic] Macro 'PvPMagic TC' created!")
        else
            print("[PvPMagic] Cannot create macro: macro limit reached.")
        end
    else
        print("[PvPMagic] Macro 'PvPMagic TC' already exists.")
    end
end

-- Create the macro on login (out of combat only)
local macroFrame = CreateFrame("Frame")
macroFrame:RegisterEvent("PLAYER_LOGIN")
macroFrame:SetScript("OnEvent", function()
    if InCombatLockdown() then
        macroFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        CreatePvPMagicTCMacro()
    end
end)
macroFrame:HookScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        CreatePvPMagicTCMacro()
        macroFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end)

-- Example: call AlertFocusTarget() from a keybind, macro, or other event
-- AlertFocusTarget()
