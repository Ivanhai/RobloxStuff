local GetGcModule = {}
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
        hookfunction(func, function(...)
            injection(...)
            return func(...)
        end)
    elseif type == "end" then
        hookfunction(func, function(...)
            func(...)
            return injection(...)
        end)
    elseif type == "replace" then
        hookfunction(func, function(...)
            return injection(...)
        end)
    end
end
function GetGcModule:UpdateOnScript(script:Script, callback):table
    script.Destroying:Connect(function()
        script.Parent:WaitForChild(script.Name)
        self:updategc()
        callback()
    end)
end
GetGcModule:updategc()

return GetGcModule