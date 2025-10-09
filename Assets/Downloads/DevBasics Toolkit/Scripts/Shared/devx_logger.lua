--!Type(Module)

--!Tooltip("Enable/Disable game logging")
--!SerializeField
local _EnableGameLogging : boolean = true

local _deferTimer : number = 0
local _printStack = {}

function DeferPrint(message: string)
  table.insert(_printStack, message)
end

function self:Update()
  if #_printStack == 0 then return end

  _deferTimer = _deferTimer - Time.deltaTime

  if _deferTimer <= 0 then
    local msg = table.remove(_printStack, 1)

    if msg then
      if _EnableGameLogging then
        print(msg)
      end
    end

    if #_printStack > 0 then
      _deferTimer = 0.1
    end
  end
end