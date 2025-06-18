-- The Center core of the addon lua files link back to here and the PvP magic toc file
-- PvPMagic Core - Main addon initialization and coordination

-- Initialize the addon namespace
PvPMagic = PvPMagic or {}

-- Core addon information
PvPMagic.version = "1.6"
PvPMagic.author = "PrincessLuna"

-- Initialize saved variables
PvPMagicDB = PvPMagicDB or {}

-- Force saved variables initialization
local function InitializeCoreVariables()
    if not PvPMagicDB then
        PvPMagicDB = {}
    end
    -- Add a timestamp to force WoW to save the variable
    PvPMagicDB.lastInitialized = time()
    print("[PvPMagic] Core saved variables initialized.")
end

-- Core initialization function
function PvPMagic:Initialize()
    InitializeCoreVariables()
    print("[PvPMagic] Core initialized - Version " .. self.version)
    print("[PvPMagic] All modules loaded successfully!")
end

-- Event frame for core initialization
local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")

coreFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "PvPMagic" then
        PvPMagic:Initialize()
    end
end)
