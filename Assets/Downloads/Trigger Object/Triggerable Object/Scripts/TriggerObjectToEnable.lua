--!Type(Client)

--!Tooltip("If true, the mesh will be enabled/disabled on all clients")
--!SerializeField
local _Syncronize : boolean = false

--!Tooltip("If true, the mesh will be hidden by default and show when triggered")
--!SerializeField
local _HideOnStart : boolean = true

--!Tooltip("If true, the sound effect will be played when the trigger is activated")
--!SerializeField
local _PlaySoundEffect : boolean = false

--!Tooltip("The sound effect to play when the trigger is activated")
--!SerializeField
local _SoundEffect : AudioClip = nil

--!Tooltip("The volume of the sound effect")
--!Range(0, 1)
--!SerializeField
local _Volume : number = 1

local _ObjectMesh : MeshRenderer = nil
local _NavMeshObstacle : NavMeshObstacle = nil

local _AudioShader : AudioShader = nil

function self:ClientAwake()
  _ObjectMesh = self.gameObject:GetComponent(MeshRenderer)

  if not _HideOnStart then
    _NavMeshObstacle = self.gameObject:GetComponent(NavMeshObstacle)
  end

  if _PlaySoundEffect then
    if _SoundEffect then
      _AudioShader = AudioShader.new(_SoundEffect)
      _AudioShader.volume = _Volume
    end
  end
end

function self:Start()
  if _ObjectMesh then
    _ObjectMesh.enabled = not _HideOnStart
  end

  function self:OnTriggerEnter(trigger : Collider)
    if _Syncronize then
      EnableMesh(_HideOnStart)
    else
      local isLocalPlayer = CheckLocalPlayer(trigger.gameObject:GetComponent(Character))
      if isLocalPlayer then
        if _PlaySoundEffect then
          Audio:PlayShader(_AudioShader)
        end
        EnableMesh(_HideOnStart)
      end
    end

    -- Disable the NavMeshObstacle so when the Mesh is disabled, the player can still move
    if not _HideOnStart then
      _NavMeshObstacle.enabled = false
    end
  end

  function self:OnTriggerExit(trigger : Collider)
    if _Syncronize then
      EnableMesh(not _HideOnStart)
    else
      local isLocalPlayer = CheckLocalPlayer(trigger.gameObject:GetComponent(Character))
      if isLocalPlayer then
        EnableMesh(not _HideOnStart)
      end
    end

    -- Enable the NavMeshObstacle when the player exits the trigger
    if not _HideOnStart then
      _NavMeshObstacle.enabled = true
    end
  end
end

function self:OnDestroy()
  if _AudioShader then
    Object.Destroy(_AudioShader)
  end
end

function CheckLocalPlayer(character: Character): boolean
  if character == nil then return false end 
  local player = character.player

  if client.localPlayer == player then 
    return true
  end

  return false
end

function EnableMesh(b : boolean)
  if _ObjectMesh then
    _ObjectMesh.enabled = b
  end
end
