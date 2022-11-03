local HookModule = {}
HookModule.__index = HookModule

function HookModule:HookRemote(remote, callback)
    if remote.ClassName == "RemoteFunction" then
        self:HookNamecall(remote, "InvokeServer", callback)
    elseif remote.ClassName == "RemoteEvent" then
        self:HookNamecall(remote, "FireServer", callback)
    end
end
function HookModule:HookNamecall(call, namecall, callback)
    self.namecall[call] = {
        namecall = namecall,
        callback = callback
    }
end
function HookModule:UnhookNamecall(hooked)
    self.namecall[hooked] = nil
end
function HookModule:HookIndex(call, key, callback)
    self.index[call] = {
        key = key,
        callback = callback
    }
end
function HookModule:UnhookIndex(hooked)
    self.index[hooked] = nil
end
function HookModule.new()
    local new = setmetatable({
        namecall = {},
        index = {},
    }, HookModule)
    local OldNameCall = nil
    OldNameCall = hookmetamethod(game, "__namecall", function(Self, ...)
        local Args = {...}
        local NamecallMethod = getnamecallmethod()
    
        if not checkcaller() then
            if new.namecall[Self] and new.namecall[Self].namecall == NamecallMethod then
                return new.namecall[Self].callback(Self, Args, OldNameCall)
            end
        end
    
        return OldNameCall(...)
    end)
    local OldIndex = nil
    OldIndex = hookmetamethod(game, "__index", function(Self, Key)
        if not checkcaller() then
            if new.index[Self] and new.index[Self].key == Key then
                return new.index[Self].callback(Self, OldIndex)
            end
        end

        return OldIndex(Self, Key)
    end)
    return new
end

return HookModule
