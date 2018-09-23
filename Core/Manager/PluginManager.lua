-- PluginManager.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 9/23/2018, 11:16:26 PM

local ns              = select(2, ...)
local Addon           = ns.Addon
local ScriptManager   = ns.ScriptManager
local PluginPrototype = {}

ns.PluginPrototype = PluginPrototype

local PluginManager = Addon:NewModule('PluginManager', 'AceEvent-3.0')

function PluginManager:OnInitialize()
    self.moduleWatings = {}
    self.moduleEnableQueue = {}
    self.pluginsOrdered = {}
    self.db = Addon.db
end

function PluginManager:OnEnable()
    self:InitPlugins()
    self:RebuildPluginOrders()

    C_Timer.After(0, function()
        self:LoadPlugins()
    end)
end

function PluginManager:GetPluginList()
    return self.pluginsOrdered
end

function PluginManager:IteratePlugins()
    return ipairs(self.pluginsOrdered)
end

function PluginManager:IterateEnabledPlugins()
    return coroutine.wrap(function()
        for _, plugin in ipairs(self.pluginsOrdered) do
            if plugin:IsEnabled() then
                coroutine.yield(plugin:GetPluginName(), plugin)
            end
        end
    end)
end

function PluginManager:InitPlugins()
    local pluginOrders = self.db.profile.pluginOrders
    local pluginOrdersMap = tInvert(pluginOrders)

    for name, plugin in self:IterateModules() do
        self.db.global.scripts[name] = self.db.global.scripts[name] or {}

        for key, db in pairs(self.db.global.scripts[name]) do
            ScriptManager:AddScript(plugin, key, Addon:GetClass('Script'):New(db, plugin, key))
        end

        if not pluginOrdersMap[name] then
            tinsert(pluginOrders, name)
            pluginOrdersMap[name] = #pluginOrders
        end
    end
end

function PluginManager:RebuildPluginOrders()
    wipe(self.pluginsOrdered)

    for _, name in ipairs(self.db.profile.pluginOrders) do
        local plugin = self:GetModule(name, true)
        print(plugin, name, plugin:GetPluginName())
        if plugin then
            tinsert(self.pluginsOrdered, plugin)
        end
    end
end

function PluginManager:LoadPlugins()
    while true do
        local module = table.remove(self.moduleEnableQueue, 1)
        if not module then
            break
        end

        if self:IsPluginAllowed(module:GetPluginName()) then
            module:Enable()
        end
    end
end

function PluginManager:ADDON_LOADED(_, addon)
    repeat
        local modules = self.moduleWatings[addon]
        if modules then
            self.moduleWatings[addon] = nil

            for _, module in ipairs(modules) do
                if self:IsPluginAllowed(module:GetPluginName()) then
                    module:Enable()
                end
            end
        end
    until not self.moduleWatings[addon]

    if not next(self.moduleWatings) then
        self:UnregisterEvent('ADDON_LOADED')
    end
end

function PluginManager:MoveUpPlugin(name)
    local pluginOrders = self.db.profile.pluginOrders
    local index = tIndexOf(pluginOrders, name)
    if not index or index == 1 then
        return
    end

    table.remove(pluginOrders, index)
    tinsert(pluginOrders, index - 1, name)

    self:RebuildPluginOrders()
end

function PluginManager:MoveDownPlugin(name)
    local pluginOrders = self.db.profile.pluginOrders
    local index = tIndexOf(pluginOrders, name)
    if not index or index == #pluginOrders then
        return
    end

    table.remove(pluginOrders, index)
    tinsert(pluginOrders, index + 1, name)

    self:RebuildPluginOrders()
end

function PluginManager:EnableModuleWithAddonLoaded(module, addon)
    module:Disable()

    if not IsAddOnLoaded(addon) then
        self.moduleWatings[addon] = self.moduleWatings[addon] or {}
        tinsert(self.moduleWatings[addon], module)

        self:RegisterEvent('ADDON_LOADED')
    else
        tinsert(self.moduleEnableQueue, module)
    end
end

function PluginManager:IsPluginAllowed(name)
    return not self.db.profile.pluginDisabled[name]
end

function PluginManager:SetPluginAllowed(name, flag)
    self.db.profile.pluginDisabled[name] = not flag or nil

    C_Timer.After(0, function()
        local module = self:GetPlugin(name)
        if flag then
            module:Enable()
        else
            module:Disable()
        end
    end)
end

---- Addon

function Addon:NewPlugin(name, ...)
    return PluginManager:NewModule(name, PluginPrototype, ...)
end

function Addon:GetPlugin(name)
    return PluginManager:GetModule(name, true)
end

function Addon:IteratePlugins()
    return PluginManager:IteratePlugins()
end

function Addon:IterateEnabledPlugins()
    return PluginManager:IterateEnabledPlugins()
end
