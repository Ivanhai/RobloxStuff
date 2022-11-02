local GetGcModule = {}
GetGcModule.__index = GetGcModule
function GetGcModule:updategc()
    self.gc = getgc()
end
function GetGcModule:getFunctionsByNameAndScript(name:string, script:Script):table
    local functions = {}
    for _, value in ipairs(self.gc) do
        if type(value) == "function" and getinfo(value).name == name and getfenv(value).script == script then
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
function GetGcModule:FunctionInject(func, type, injection)
    if type == "start" then
        local old
        old = hookfunction(func, function(...)
            injection(...)
            old(...)
        end)
    elseif type == "end" then
        local old
        old = hookfunction(func, function(...)
            old(...)
            injection(...)
        end)
    elseif type == "replace" then
        hookfunction(func, function(...)
            injection(...)
        end)
    end
end
function GetGcModule:UpdateOnStarterScript(script:Script, callback):table
    local hash = getscripthash(script)
    local Starter = {
        "PlayerScripts",
        "PlayerGui"
    }
    local ancestor:Instance
    for _, path in ipairs(Starter) do
        if not script:FindFirstAncestor(path) then
            continue
        end
        ancestor = script:FindFirstAncestor(path)
    end
    ancestor.DescendantAdded:Connect(function(descendant)
        if descendant:IsA(script.ClassName) and getscripthash(descendant) == hash then
            -- wait for script to end
            task.wait(1)
            ---------------------------
            self:updategc()
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
