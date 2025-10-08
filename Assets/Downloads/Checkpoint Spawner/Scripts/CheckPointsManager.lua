--!Type(Module)

--!Tooltip("If you reach a check point, the old check points will be disabled")
--!SerializeField
local _DisableCheckPointsOnReach : boolean = true

--!Tooltip("Play audio on change check point")
--!SerializeField
local _PlayAudioOnChange : boolean = true

--!Tooltip("Audio clip to play when changing check point")
--!SerializeField
local _AudioClip : AudioShader = nil

--!Tooltip("Display popup on change check point")
--!SerializeField
local _DisplayPopupOnChange : boolean = true

--!Tooltip("List of check points")
--!SerializeField
local _CheckPoints : { GameObject } = {} -- Default index is 1

--!Tooltip("The main check point")
--!SerializeField
local _DefaultCheckPointID : number = 1

--!Tooltip("Play particles on spawn")
--!SerializeField
local _PlayParticlesOnSpawn : boolean = true

--!Tooltip("Particles to play on spawn")
--!SerializeField
local _ParticlesOnSpawn : GameObject = nil

--!Tooltip("Duration of the particles on spawn")
--!SerializeField
local _ParticlesOnSpawnDuration : number = 5

--!Tooltip("Storage key")
--!SerializeField
local _StorageKey : string = "CheckPoint"

-- Events
local ChangeCheckPointRequest = Event.new("ChangeCheckPointRequest")
local ChangeCheckPointResponse = Event.new("ChangeCheckPointResponse")

local GetCurrentCheckPointIDRequest = Event.new("GetCurrentCheckPointIDRequest")
local GetCurrentCheckPointIDResponse = Event.new("GetCurrentCheckPointIDResponse")

local SyncCheckPointPositionsRequest = Event.new("SyncCheckPointPositionsRequest")

local CheckPointCallbacks = {}
local currentCheckPointID : number = 1
local checkPointPositions : { Vector3 } = {}


--[[
  MapCheckPoints: Maps the check points to their positions.
  @param checkPoints: { Transform }
  @return { Vector3 }
]]
local function MapCheckPoints(checkPoints: { GameObject }): { Vector3 }
  checkPointPositions = {} -- Reset the positions array
  for i, checkPoint in ipairs(checkPoints) do
    checkPointPositions[i] = checkPoint.transform.position
  end

  return checkPointPositions
end

--[[
  DisableCheckPoints: Disables the older check points <= currentCheckPointID
]]
function DisableCheckPoints(c: number)
  for i = 1, c do
    local checkPoint = _CheckPoints[i]
    if checkPoint and checkPoint.activeSelf then
      checkPoint:SetActive(false)
    end
  end
end

--[[
  GenerateRandomRequestId: Generates a random request ID.
  @return string
]]
local function GenerateRandomRequestId(): string
  local requestId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
  return requestId
end

--[[
  SetNewCheckPoint: Sets a new check point.
  @param checkPointID: number
]]
function SetNewCheckPoint(checkPointID: number)
  if not client then
    print("SetNewCheckPoint: Must be called from client")
    return
  end
  
  if currentCheckPointID >= checkPointID then
    return
  end
  
  -- If validation passes, send request to server
  local requestId = GenerateRandomRequestId()
  ChangeCheckPointRequest:FireServer(checkPointID, requestId)
end

--[[
  OnCheckPointChangedResponse: Handles the response from the server when a check point is changed.
  @param requestId: string
  @param success: boolean
  @param message: string
]]
local function OnCheckPointChangedResponse(requestId: string, checkPointID: number, success: boolean, message: string)
  local callback = CheckPointCallbacks[requestId]
  if callback then
    callback(success, message)
    CheckPointCallbacks[requestId] = nil
  end
  
  if success then
    currentCheckPointID = checkPointID

    if _DisableCheckPointsOnReach then
      DisableCheckPoints(checkPointID)
    end

    if _PlayAudioOnChange and _AudioClip then
      Audio:PlayShader(_AudioClip)
    end

    if _DisplayPopupOnChange then
      local popup = self.gameObject:GetComponent(checkpointpopupui)
      if popup then
        popup.Flash()
      end
    end
  end
end

--[[
  OnClientGetCurrentCheckPointIDResponse: Handles the response from the server when the current check point is requested.
  @param player: Player
  @param checkPointID: number
]]
local function OnClientGetCurrentCheckPointIDResponse(player: Player, checkPointID: number)
  local character = player.character

  currentCheckPointID = checkPointID
  local checkPointPosition = _CheckPoints[checkPointID].transform.position
  character:Teleport(checkPointPosition)
  
  if _PlayParticlesOnSpawn and _ParticlesOnSpawn then
    local particleComponent = nil
    local particleObject = Object.Instantiate(_ParticlesOnSpawn, checkPointPosition)
    particleComponent = particleObject:GetComponent(ParticleSystem)

    if particleComponent ~= nil then
      particleComponent:Play()

      Timer.After(_ParticlesOnSpawnDuration, function()
        Object.Destroy(particleObject)
      end)
    end
  end

  if _DisableCheckPointsOnReach and player == client.localPlayer then
    DisableCheckPoints(checkPointID)
  end
end

--[[
  FireGetCurrentCheckPointIDRequest: Fires a request to the server to get the current check point ID.
]]
local function FireGetCurrentCheckPointIDRequest()
  GetCurrentCheckPointIDRequest:FireServer()
end

function self:ClientAwake()
  -- Map the checkpoints first
  MapCheckPoints(_CheckPoints)
  
  -- Then send the mapped positions to the server
  SyncCheckPointPositionsRequest:FireServer(checkPointPositions)
  Timer.After(0.1, FireGetCurrentCheckPointIDRequest)
end

function self:ClientStart()
  if #_CheckPoints == 0 then
    print("[CheckPointsManager] No check points found")
    return
  end

  GetCurrentCheckPointIDResponse:Connect(OnClientGetCurrentCheckPointIDResponse)
  ChangeCheckPointResponse:Connect(OnCheckPointChangedResponse)
end

----------------------------------------------------------
-------------------------- SERVER ------------------------
local ServerCheckPoints = {}

--[[
  OnServerCheckPointChanged: Handles the request from the client to change the check point.
  @param player: Player
  @param checkPointID: number
  @param requestId: string
]]
local function OnServerCheckPointChanged(player: Player, checkPointID: number, requestId: string)
  if not server then
    print("OnServerCheckPointChanged: Must be called from server")
    return
  end

  if checkPointID == currentCheckPointID then
    print("OnServerCheckPointChanged: You're already at this check point")
    ChangeCheckPointResponse:FireClient(player, requestId, checkPointID, false, "You're already at this check point")
    return
  end

  if currentCheckPointID> checkPointID then
    print("OnServerCheckPointChanged: You can't go back to a previous check point")
    ChangeCheckPointResponse:FireClient(player, requestId, checkPointID, false, "You can't go back to a previous check point")
    return
  end

  Storage.SetPlayerValue(player, _StorageKey, checkPointID)
  ChangeCheckPointResponse:FireClient(player, requestId, checkPointID, true, "Check point changed successfully")
end

--[[
  OnServerCheckPointPositionSync: Handles the request from the client to sync the check point positions.
  @param player: Player
  @param checkPoints: { Vector3 }
]]
local function OnServerCheckPointPositionSync(player: Player, checkPoints: { Vector3 })
  -- Add nil check to prevent ipairs error
  if checkPoints then
    ServerCheckPoints = checkPoints
  else
    print("[CheckPointsManager] Error: Received nil checkpoint positions from client")
  end
end

--[[
  ServerTeleport: Teleports the player to the check point.
  @param player: Player
  @param checkPointID: number
]]
local function ServerTeleport(player: Player, checkPointID: number)
  local character = player.character
  if ServerCheckPoints and ServerCheckPoints[currentCheckPointID] then
    character.transform.position = ServerCheckPoints[currentCheckPointID]

    GetCurrentCheckPointIDResponse:FireAllClients(player, checkPointID)
  else
    print("[CheckPointsManager] Warning: Cannot teleport player - checkpoint position not available")
  end
end

--[[
  OnServerGetCurrentCheckPointID: Handles the request from the client to get the current check point ID.
  @param player: Player
]]
local function OnServerGetCurrentCheckPointID(player: Player)
  Storage.GetPlayerValue(player, _StorageKey, function(value)
    if value == nil then
      value = _DefaultCheckPointID
      Storage.SetPlayerValue(player, _StorageKey, value)
    end

    ServerTeleport(player, value)
  end)
end

function self:ServerAwake()
  SyncCheckPointPositionsRequest:Connect(OnServerCheckPointPositionSync)
end

function self:ServerStart()
  GetCurrentCheckPointIDRequest:Connect(OnServerGetCurrentCheckPointID)
  ChangeCheckPointRequest:Connect(OnServerCheckPointChanged)
end