--[[
Addon.lua
@Author  : DengSir (tdaddon@163.com)
@Link    : https://dengsir.github.io
]]

local ns    = select(2, ...)
local Addon = LibStub('AceAddon-3.0'):NewAddon('tdBattlePetScript', 'AceEvent-3.0', 'LibClass-2.0')

ns.Addon = Addon
ns.UI    = {}
ns.L     = LibStub('AceLocale-3.0'):GetLocale('tdBattlePetScript', true)

_G.tdBattlePetScript = Addon

function Addon:OnInitialize()
    local defaults = {
        global = {
            scripts = {

            }
        },
        profile = {
            pluginDisabled = {

            },
            settings = {
                autoSelect         = true,
                hideNoScript       = false,
                noWaitDeleteScript = false,
                editorFontFace     = STANDARD_TEXT_FONT,
                editorFontSize     = 14,
                autoButtonHotKey   = 'A',
                testBreak          = true,
            },
            minimap = {
                minimapPos = 50,
            },
            position = {
                point = 'CENTER', x = 0, y = 0, width = 350, height = 450,
            },
            pluginOrders = {
                'Rematch',
                'Base',
                'AllInOne',
            }
        }
    }
    self.db = LibStub('AceDB-3.0'):New('TD_DB_BATTLEPETSCRIPT_GLOBAL', defaults, true)

    self.db.RegisterCallback(self, 'OnDatabaseShutdown')
end

function Addon:OnEnable()
    self:RegisterMessage('PET_BATTLE_SCRIPT_SCRIPT_ADDED')
    self:RegisterMessage('PET_BATTLE_SCRIPT_SCRIPT_REMOVED')

    C_Timer.After(0, function()
        self:InitSettings()
        self:LoadOptionFrame()
    end)
end

function Addon:InitSettings()
    for key, value in pairs(self.db.profile.settings) do
        self:SetSetting(key, value)
    end
end

function Addon:OnModuleCreated(module)
    local name = module:GetName()
    if name:find('^UI%.') then
        ns.UI[name:match('^UI%.(.+)$')] = module
    else
        ns[module:GetName()] = module
    end
end

function Addon:OnDatabaseShutdown()
    self:SendMessage('PET_BATTLE_SCRIPT_DB_SHUTDOWN')
end

function Addon:PET_BATTLE_SCRIPT_SCRIPT_ADDED(_, plugin, key, script)
    self.db.global.scripts[plugin:GetPluginName()][key] = script:GetDB()
end

function Addon:PET_BATTLE_SCRIPT_SCRIPT_REMOVED(_, plugin, key)
    self.db.global.scripts[plugin:GetPluginName()][key] = nil
end

function Addon:GetSetting(key)
    return self.db.profile.settings[key]
end

function Addon:SetSetting(key, value)
    self.db.profile.settings[key] = value
    self:SendMessage('PET_BATTLE_SCRIPT_SETTING_CHANGED', key, value)
    self:SendMessage('PET_BATTLE_SCRIPT_SETTING_CHANGED_' .. key, value)
end
