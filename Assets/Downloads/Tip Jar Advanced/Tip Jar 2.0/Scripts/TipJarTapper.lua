--!Type(Client)

--!Tooltip("The main UI for the tip jar")
--!SerializeField
local _TipJarUI : GameObject = nil

function self:Awake()
  local tapper = self.gameObject:GetComponent(TapHandler)
  tapper.Tapped:Connect(function()
      if not _TipJarUI.activeSelf then 
          _TipJarUI:SetActive(true)
      end
  end)
end