local GetGcModule = {}
GetGcModule.__index = GetGcModule
function GetGcModule:updategc()
    self.gc = getgc()
end
function GetGcModule:getFunctionByNameAndScript(name:string, script:Script):table
    for _, value in ipairs(self.gc) do
        if type(value) == "function" and getinfo(value).name == name and getfenv(value).script == script then
            return value
        end
    end
end
function GetGcModule:getFunctionsByScript(script:Script):table
    local functions = {}
    for _, value in ipairs(self.gc) do
        if type(value) == "function" and getfenv(value).script == script then
            table.insert(functions, value)
        end
    end
    return functions
end
function GetGcModule:getFunctionsByName(name:string):table
    local functions = {}
    for _, value in ipairs(self.gc) do
        if type(value) == "function" and getinfo(value).name == name then
            table.insert(functions, value)
        end
    end
    return functions
end
function GetGcModule:WatchScript(script:Script, callback, init:boolean)
    if init then callback(script) end
    local OldFunctionsLength = #self:getFunctionsByScript(script)
    local hash = getscripthash(script)
    -- getting ancestor that will not be destroyed
    local Starter = {
        "PlayerGui",
        game.Players.LocalPlayer.Character.Parent.Name
    }
    local ancestor:Instance
    for _, path in ipairs(Starter) do
        if not script:FindFirstAncestor(path) then
            continue
        end
        ancestor = script:FindFirstAncestor(path)
    end
    if not ancestor then return end
    ancestor.DescendantAdded:Connect(function(descendant)
        if descendant:IsA(script.ClassName) and getscripthash(descendant) == hash then
            while #self:getFunctionsByScript(descendant) <= OldFunctionsLength do
                self:updategc()
                task.wait(1)
            end
            callback(descendant)
        end
    end)
end
function GetGcModule.new()
    local new = setmetatable({}, GetGcModule)
    new:updategc()
    return new
end

return GetGcModule
