--!Type(Client)


--!SerializeField
local _UIPanels : GameObject = nil

--!SerializeField
local _Type : string = "Progress"

local UIPanelScript = nil
local function Init()
  if UIPanelScript == nil then
    UIPanelScript = _UIPanels:GetComponent(panels)
  end
end

function self:Awake()
  Init()
end

function self:Start()
  local tapper = self.gameObject:GetComponent(TapHandler)
  tapper.Tapped:Connect(function()
    if _Type == "Progress" then
      UIPanelScript.ShowProgress("Progress", "Please wait while we process your request...", 3.0, function()
        print("Progress completed")
      end, function()
        print("Progress cancelled")
      end)
    elseif _Type == "Notification" then
      UIPanelScript.ShowNotification("success", "Success!", "Operation completed successfully", 3.0)
    elseif _Type == "Confirmation" then
      UIPanelScript.ShowConfirmation("Confirmation", "Are you sure you want to do this?", function()
        print("Confirmation completed")
      end, function()
        print("Confirmation cancelled")
      end)
    elseif _Type == "Input" then
      UIPanelScript.ShowInput("Create Item", "Name: ", "Enter item name...", "Description: ", "Enter item description...", function()
        print("Input submitted")
      end, function()
        print("Input cancelled")
      end)
    elseif _Type == "Switches" then
      UIPanelScript.ShowSwitches("Game Settings", {
        { label = "Enable Sound", checked = true },
        { label = "Show Notifications", checked = false },
        { label = "Auto Save", checked = true },
      }, function()
        print("Switches submitted")
      end, function()
        print("Switches cancelled")
      end)
    elseif _Type == "Sliders" then
      UIPanelScript.ShowSliders("Game Settings", {
        { label = "Volume", value = 50, min = 0, max = 100 },
        { label = "Brightness", value = 75, min = 0, max = 100 },
        { label = "Speed", value = 5, min = 1, max = 10 },
      }, function()
        print("Sliders submitted")
      end, function()
        print("Sliders cancelled")
      end)
    elseif _Type == "Dropdowns" then
      UIPanelScript.ShowDropdowns("Game Settings", function()
        print("Dropdowns submitted")
      end, function()
        print("Dropdowns cancelled")
      end)
    elseif _Type == "Tooltip" then
      UIPanelScript.ShowTooltip("This is a helpful tooltip", { x = 100, y = 200 })
      Timer.After(1, function()
        UIPanelScript.HideTooltip()
      end)
    end
  end)
end