local E = unpack(ElvUI)
local EP = E.Libs.EP

local core = {
	modules = {},
	defaultDB = {},
	MODULE_ORDER = {"DataTexts", "MiscTweaks", "OptionsTweaks"},
}

_G.ElvUIEnhancedTweaker = core

local function CopyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			if type(value) == "table" then
				target[key] = CopyDefaults({}, value)
			else
				target[key] = value
			end
		elseif type(value) == "table" and type(target[key]) == "table" then
			CopyDefaults(target[key], value)
		end
	end

	return target
end

function core:RegisterModule(name, module, defaults)
	self.modules[name] = module
	self.defaultDB[name] = defaults
end

function core:RegisterSubmoduleDefaults(moduleName, name, defaults)
	local moduleDefaults = self.defaultDB[moduleName]
	if moduleDefaults then
		moduleDefaults[name] = defaults or {}
	end
end

function core:GetCore()
	return self
end

function core:GetDB()
	return self.db or {}
end

function core:RefreshDB()
	local usePerCharacter = ElvUI_WotLK_TweakerDBPC and ElvUI_WotLK_TweakerDBPC.usePerCharacter
	local db

	if usePerCharacter then
		ElvUI_WotLK_TweakerDBPC.profile = ElvUI_WotLK_TweakerDBPC.profile or {}
		db = ElvUI_WotLK_TweakerDBPC.profile
	else
		ElvUI_WotLK_TweakerDB = ElvUI_WotLK_TweakerDB or {}
		db = ElvUI_WotLK_TweakerDB
	end

	for name, defaults in pairs(self.defaultDB) do
		db[name] = CopyDefaults(db[name] or {}, defaults)
		local module = self.modules[name]
		if module then
			module.db = db[name]
		end
	end

	self.db = db
end

local function InjectConfig()
	if not E.Options then return end

	local config = {
		type = "group",
		name = "|cffa855f7Tweaker|r",
		order = 3,
		childGroups = "tab",
		args = {
			perCharacter = {
				type = "group",
				name = "General",
				order = 1,
				args = {
					usePerCharacter = {
						type = "toggle",
						name = "Apply only for this character",
						desc = "Settings will only apply to this character when enabled.",
						order = 1,
						get = function()
							return ElvUI_WotLK_TweakerDBPC and ElvUI_WotLK_TweakerDBPC.usePerCharacter
						end,
						set = function(_, value)
							ElvUI_WotLK_TweakerDBPC = ElvUI_WotLK_TweakerDBPC or {}
							ElvUI_WotLK_TweakerDBPC.usePerCharacter = value
							core:RefreshDB()
						end,
					},
				},
			},
		},
	}

	for order, name in ipairs(core.MODULE_ORDER) do
		local module = core.modules[name]
		if module and module.GetOptions then
			config.args[name] = module:GetOptions(core:GetDB()[name])
			config.args[name].order = order + 1
		end
	end

	E.Options.args.Tweaker = config

	local function SetNavigationOrder()
		local options = E.Options.args
		if options.Tweaker then options.Tweaker.order = 3 end
		if options.addOnSkins then options.addOnSkins.order = 4 end
		for _, name in ipairs({"actionbar", "auras", "bags", "chat", "cooldown", "databars", "datatexts", "maps", "nameplate", "skins", "tooltip", "unitframe", "tagGroup", "profiles"}) do
			if options[name] then options[name].order = 5 end
		end
		if options.modulecontrol then options.modulecontrol.order = 6 end
		if options.filters then options.filters.order = 6 end
	end

	SetNavigationOrder()
	if C_Timer and C_Timer.After then
		C_Timer.After(0, SetNavigationOrder)
	end

	if E.Libs.AceConfigRegistry then
		E.Libs.AceConfigRegistry:NotifyChange("ElvUI")
	end
end

function core:InjectOptions()
	self:RefreshDB()
	InjectConfig()
end

function core:InitializeOptions()
	self:RefreshDB()
	EP:RegisterPlugin("ElvUI_Enhanced_Tweaker", InjectConfig)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
	core:RefreshDB()
	if E.Options then
		InjectConfig()
	end
end)
