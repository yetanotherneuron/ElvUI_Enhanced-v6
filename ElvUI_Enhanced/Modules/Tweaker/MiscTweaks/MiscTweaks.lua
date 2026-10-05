
local core = ElvUIEnhancedTweaker
local L = LibStub("AceLocale-3.0-ElvUI"):GetLocale("ElvUI", true)
if not L then L = setmetatable({}, { __index = function(t, k) return k end }) end

local MOD = {}
_G.ElvUIEnhancedTweaker_MiscTweaks = MOD

if not core then return end
print("|cff00ff00[MiscTweaks]|r MiscTweaks.lua running")

-- L and MOD now defined above
MOD.name = L["MiscTweaks"]
MOD.defaults = {
    EmbedTweaks = {},
    FiveSecondRule = {},
    GameTimeDisplay = {},
    TooltipAnchor = {},
    ShapeshiftRemover = {},
    ChatEditboxMover = {},
    VendorTweaks = {},
    BagSwap = {},
    MicrobarTweaks = {},
    RollSave = {},
}
MOD.submodules = {}

function MOD:RegisterSubmodule(name, tbl)
    MOD.submodules[name] = tbl
    core:RegisterSubmoduleDefaults("MiscTweaks", name, tbl.defaults or MOD.defaults[name])
end

function MOD:GetOptions(db)
    db = db or (core and core.GetDB and core:GetDB().MiscTweaks) or {}
    self.db = db
    local opts = {
        type = "group",
        name = self.name,
        childGroups = "tab",
        args = {},
    }
    local order = 1
    for key, sub in pairs(self.submodules) do
        if sub.GetOptions then
            if not db[key] then db[key] = {} end
            opts.args[key] = sub:GetOptions(db[key])
            opts.args[key].order = order
            opts.args[key].name = sub.name or key
        end
        order = order + 1
    end
    return opts
end

function MOD:ApplyEnabledModules()
    local db = (core and core.GetDB and core:GetDB().MiscTweaks) or {}
    self.db = db
    for key, sub in pairs(self.submodules) do
        local subdb = db[key]
        if subdb and subdb.enabled then
            if sub.ApplyEnabled then
                sub:ApplyEnabled(subdb)
            elseif sub.OnEnable then
                sub:OnEnable(subdb)
            end
        elseif sub and sub.OnDisable then
            sub:OnDisable(subdb)
        elseif sub and sub.DisableAnchor then
            sub:DisableAnchor()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    MOD:ApplyEnabledModules()
end)

core:RegisterModule("MiscTweaks", MOD, MOD.defaults)

-- Already set at the top
