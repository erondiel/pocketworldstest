--!Type(Module)

--!SerializeField
local _EnableLogging : boolean = false

type RegisteredUI = {
  [string]: GameObject
}

local _RegisteredUIs : RegisteredUI = {}
local _IsInitialized : boolean = false

-- Static UI is UI that is always visible.
local StaticUI = {
  "DevX_HUD"
}

--[[
  init: Initializes the UI manager.
]]
function init()
  if _IsInitialized then return end

  local childCount = self.transform.childCount
  for i = 0, childCount - 1 do
    local ui = self.transform:GetChild(i).gameObject
    _RegisteredUIs[ui.name] = ui

    if _EnableLogging then
      print("Registered UI: " .. ui.name)
    end
  end

  _IsInitialized = true
end

--[[
  getUI: Gets a UI by name.
  @param name: string
  @return GameObject | nil
]]
function getUI(name: string): GameObject | nil
  return _RegisteredUIs[name]
end

--[[
  showUI: Shows a UI by name.
  @param name: string
]]
function showUI(name: string)
  local ui = getUI(name)
  if ui and not ui.activeSelf then ui:SetActive(true) end
end

--[[
  hideUI: Hides a UI by name.
  @param name: string
]]
function hideUI(name: string)
  local ui = getUI(name)
  if ui and ui.activeSelf then ui:SetActive(false) end
end

--[[
  toggleUI: Toggles a UI by name.
  @param name: string
]]
function toggleUI(name: string)
  local ui = getUI(name)
  if ui then ui:SetActive(not ui.activeSelf) end
end

--[[
  isUIActive: Checks if a UI is active.
  @param name: string
  @return boolean
]]
function isUIActive(name: string): boolean
  local ui = getUI(name)
  return ui and ui.activeSelf
end

--[[
  UpdateCurrency: Updates the currency label.
  @param amount: number
]]
function UpdateCurrency(newValue: number, oldValue: number)
  local GameHud = getUI("DevX_HUD")
  if not GameHud then return end

  local GameHudComp = GameHud:GetComponent(devx_hud)
  if not GameHudComp then return end

  GameHudComp.UpdateCurrency(newValue, oldValue)
end

--[[
  OpenLeaderboard: Opens the leaderboard.
]]
function OpenLeaderboard()
  toggleUI("DevX_Leaderboard")
end

--[[
  OpenShop: Opens the shop.
]]
function OpenShop()
  toggleUI("DevX_Shop")
end

function self:Start()
  init()
end