--!Type(Module)

CustomEvents = Event.new("CustomEvents")

function FireCustomEvent(customString:string)
    CustomEvents:Fire(customString)
end

OnCutsceneStart = Event.new("OnCutsceneStart")

function FireStartEvent(cutsceneName:string)
    OnCutsceneStart:Fire(cutsceneName)
end

OnCutsceneEnd = Event.new("OnCutsceneEnd")

function FireEndEvent(cutsceneName:string)
    OnCutsceneEnd:Fire(cutsceneName)
end