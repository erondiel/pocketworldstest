--!Type(Client)

-- PropOutline.lua
-- Simple outline controller for possessable props
-- Manages visibility of outline mesh renderer child

local outlineRenderer : MeshRenderer = nil
local outlineName : string = "_Outline"

function self:ClientAwake()
    -- Find outline mesh renderer in children
    local childCount = self.transform.childCount
    for i = 0, childCount - 1 do
        local child = self.transform:GetChild(i)
        if child.name:find(outlineName) then
            outlineRenderer = child.gameObject:GetComponent(MeshRenderer)
            if outlineRenderer then
                print("[PropOutline] Found outline renderer on " .. self.gameObject.name)
                break
            end
        end
    end

    if not outlineRenderer then
        print("[PropOutline] Warning: No outline renderer found for " .. self.gameObject.name)
    end
end

function self:Start()
    -- Hide outline by default
    if outlineRenderer then
        outlineRenderer.enabled = false
    end
end

-- Public API
function self:ShowOutline()
    if outlineRenderer then
        outlineRenderer.enabled = true
    end
end

function self:HideOutline()
    if outlineRenderer then
        outlineRenderer.enabled = false
    end
end

function self:IsOutlineVisible()
    if outlineRenderer then
        return outlineRenderer.enabled
    end
    return false
end
