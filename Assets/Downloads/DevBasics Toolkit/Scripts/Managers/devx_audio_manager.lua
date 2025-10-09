--!Type(Module)

--!Tooltip("List of audio shaders - starting index 1")
--!SerializeField
local _AudioShaders : { AudioShader } = {}

--!Tooltip("Enable/Disable SFX")
--!SerializeField
local _EnableSFX : boolean = true

-- Map of audio name to shader index
local AUDIO_MAP = {
  ["SFX_Button_Click"] = 1,
  -- Add more audio names here
}

-- Internal shader playback
local function PlayAudioShader(id: number)
  local shader = _AudioShaders[id]
  if shader then
    Audio:PlayShader(shader)
  end
end

function Play(name: string)
  if not _EnableSFX then return end

  local id = AUDIO_MAP[name]
  if id then
    PlayAudioShader(id)
  else
    print("[DevX_AudioManager] Unknown audio name:", name)
  end
end