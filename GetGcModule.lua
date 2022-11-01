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
function GetGcModule:UpdateOnScript(script:Script, callback):table
    local function update(script, callback)
        script.Destroying:Connect(function()
            local new = script.Parent:WaitForChild(script.Name)
            update(new, callback)
            self:updategc()
            callback()
        end)
    end
    update(script, callback)
end
GetGcModule:updategc()

return GetGcModule
