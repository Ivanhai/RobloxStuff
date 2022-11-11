local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService('StarterGui')
local LocalPlayer = Players.LocalPlayer

local GetStructureModel = ReplicatedStorage.RemoteFunctions.GetStructureModel
local PlaceStructure = ReplicatedStorage.RemoteFunctions.PlaceStructure
local ShoutMessage = ReplicatedStorage.RemoteEvents.ShoutMessage
local SetFlagDecal = ReplicatedStorage.RemoteEvents.SetFlagDecal

function getRoot(char)
	local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
	return rootPart
end
function float()
    local T = getRoot(LocalPlayer.Character)
    local BG = Instance.new('BodyGyro')
	local BV = Instance.new('BodyVelocity')
	BG.P = 9e4
	BG.Parent = T
	BV.Parent = T
	BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	BG.cframe = T.CFrame
	BV.velocity = Vector3.new(0, 0, 0)
	BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
end
function unfloat()
    local T = getRoot(LocalPlayer.Character)
    if T:FindFirstChild("BodyGyro") then
        T:FindFirstChild("BodyGyro"):Destroy()
    end
    if T:FindFirstChild("BodyVelocity") then
        T:FindFirstChild("BodyVelocity"):Destroy()
    end
    if LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
		LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
	end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end
function findTable(table, key, value)
    for index, table in ipairs(table) do
        if(table[key] == value) then
            return index, table
        end
    end
end
function EquipTool(tool:Tool)
    local Humanoid = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    Humanoid:UnequipTools()
    Humanoid:EquipTool(tool)
end
function EncodeCFrame(cfr:CFrame)
	return {cfr:GetComponents()}
end
function DecodeCFrame(tbl)
    return CFrame.new(unpack(tbl))
end
function ChangeCamera()
    local SpawnGui = LocalPlayer.PlayerGui:WaitForChild("SpawnGui")
    SpawnGui.Enabled = false;
	SpawnGui:SetAttribute("Spawned", true);
    task.wait(1)
	workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid;
	LocalPlayer.CameraMaxZoomDistance = 35;
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true);
end
function GetPartRelative(part:BasePart, newPos:CFrame):CFrame
	local model = part.Parent
	if not model:IsA("Model") then error("Parent not a model") end
	local center = model:GetBoundingBox()
	local RelativePosition = center:ToObjectSpace(part.CFrame)
	local NewCFrame = newPos * RelativePosition
	return NewCFrame
end
local StructureModule = {}
StructureModule.__index = StructureModule
function StructureModule.new(Waterloo, building, cost)
    local self = setmetatable({
        Waterloo = Waterloo,
        building = building,
        cost = cost,
        Center = Vector3.zero,
        changedName = {},
        Relative = {}
    }, StructureModule)

    local OldIndex = nil
    OldIndex = hookmetamethod(game, "__index", function(Self, Key)
        if checkcaller() and Self == workspace.Structures and self.changedName[Key] then
            return self.changedName[Key]
        end

        return OldIndex(Self, Key)
    end)
    return self
end
function StructureModule:Spawn()
    for _,structure in ipairs(self.building) do
        if not structureCache[structure.name] then
            local model = GetStructureModel:InvokeServer(structure.name):Clone()
            model.Parent = nil
            structureCache[structure.name] = model
        end
        local model = structureCache[structure.name]:Clone()
        model:SetPrimaryPartCFrame(DecodeCFrame(structure.cframe))
        model.Parent = workspace
        if structure.message then
            if structure.name == "DecalSign" then
                model.Center.ImageGui.ImageLabel.Image = "rbxassetid://"..structure.message
            elseif structure.name == "LargeSign" or structure.name == "SmallSign" or structure.name == "OverhangSign" then
                model.Center.TextGui.Display.Text = structure.message
            elseif structure.name == "Fort" then
                model.Center.FortGui.FortName.Text = structure.message
                if structure.fortDecal then
                    for _,instance in ipairs(model.ActualFlag:GetChildren()) do
                        instance.TextureID = "rbxassetid://"..structure.fortDecal
                    end
                end
            end
        end
        structure.Model = model
    end
    for _,structure in ipairs(self.building) do
        self.Center = self.Center + structure.Model.PrimaryPart.Position
    end
    self.Center = self.Center / #self.building
    for _, structure in ipairs(self.building) do
	    self.Relative[structure.Model] = structure.Model.PrimaryPart.Position - self.Center
    end
end
function StructureModule:TeleportAndBuild(cframe, name, message, fortDecal, InGameName):number
    local response
    getRoot(LocalPlayer.Character).CFrame = cframe
    while not response do
        response = PlaceStructure:InvokeServer(workspace.Terrain, Enum.Material.Sandstone, name, cframe)
    end
    if message then
        ShoutMessage:FireServer(message, self.Waterloo.createdStructure)
    end
    if fortDecal then
        SetFlagDecal:FireServer(fortDecal)
    end
    if InGameName then
        self.changedName[InGameName] = self.Waterloo.createdStructure
    end
    return response
end
function StructureModule:Build()
    if not self.building[1].Model then
        error("Spawn the structure first")
    end
    if not LocalPlayer.Backpack:FindFirstChild("Hammer") and not LocalPlayer.Character:FindFirstChild("Hammer") then
        error("No hammer found")
    end
    local cframe = CFrame.new()
    local connection = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        float()
        ChangeCamera()
        getRoot(LocalPlayer.Character).CFrame = cframe
        EquipTool(LocalPlayer.Backpack.Hammer)
    end)
    float()
    EquipTool(LocalPlayer.Backpack.Hammer)
    for _,structure in ipairs(self.building) do
        cframe = structure.Model.PrimaryPart.CFrame
        local newTokens = self:TeleportAndBuild(cframe, structure.name, structure.message, structure.fortDecal, structure.InGameName)
        LocalPlayer.PlayerGui:WaitForChild("BuildGui"):WaitForChild("Backing"):WaitForChild("Tokens").Text = "Materials: "..newTokens
        repeat task.wait() until not self.paused
    end
    unfloat()
    connection:Disconnect()
end
function StructureModule:Move(newpos:Vector3)
    if not self.building[1].Model then
        error("Spawn the structure first")
    end
    for Model, RelativePosition in pairs(self.Relative) do
        local cframe = CFrame.new(newpos + RelativePosition) * CFrame.Angles(Model.PrimaryPart.CFrame:ToOrientation())
        Model:SetPrimaryPartCFrame(cframe)
    end
end
function StructureModule:SetProperty(property:string, value)
    if not self.building[1].Model then
        error("Spawn the structure first")
    end
    for Model, _ in pairs(self.Relative) do
        Model[property] = value
    end
end
function StructureModule:Destroy()
    if not self.building[1].Model then
        error("Spawn the structure first")
    end
    for Model, _ in pairs(self.Relative) do
        Model:Destroy()
    end
    self.Relative = {}
    self.Center = Vector3.zero
end
function StructureModule:SetPausedState(state)
    self.paused = state
end

local WaterlooModule = {}
WaterlooModule.__index = WaterlooModule
function WaterlooModule.new()
    if not structureCache then
        structureCache = {}
    end
    local self = setmetatable({}, WaterlooModule)
    self.buildingsNames = {}
    for _,instance in ipairs(LocalPlayer.PlayerGui:WaitForChild("BuildGui"):WaitForChild("Backing"):GetDescendants()) do
        if instance:IsA("ImageButton") then
            table.insert(self.buildingsNames, instance.Name)
        end
    end
    workspace.Structures.ChildAdded:Connect(function(child)
        if child:GetAttribute("OwnerName") == LocalPlayer.Name then
            self.createdStructure = child
        end
    end)
    workspace.ChildAdded:Connect(function(child)
        if child:GetAttribute("Cost") then
            self.selectedStructure = child
        end
    end)
    workspace.ChildRemoved:Connect(function(child)
        if child == self.selectedStructure then
            self.selectedStructure = nil
        end
    end)
    return self
end
function WaterlooModule:SaveStructureToFile(models, filePath)
    local file = {building = {}, cost = 0}
    for _, model in ipairs(models) do
        if not model:IsDescendantOf(workspace.Structures) then continue end
        local resultTable = {
            name = model.Name,
        }
        -- useful for botting (use dex to set names)
        if not table.find(self.buildingsNames, resultTable.name) then
            local InGameNameAndStructureName = model.Name:split('|')
            resultTable.InGameName = InGameNameAndStructureName[1]
            resultTable.name = InGameNameAndStructureName[2]
        end
        ----------
        if not structureCache[resultTable.name] then
            local model = GetStructureModel:InvokeServer(resultTable.name):Clone()
            model.Parent = nil
            structureCache[resultTable.name] = model
        end
        local cframe = GetPartRelative(structureCache[resultTable.name].PrimaryPart, model:GetBoundingBox())
        resultTable.cframe = EncodeCFrame(cframe)
        if resultTable.name == "DecalSign" then
            resultTable.message = model.Center.ImageGui.ImageLabel.Image:split('//')[2]
        elseif resultTable.name == "LargeSign" or resultTable.name == "SmallSign" or resultTable.name == "OverhangSign" then
            resultTable.message = model.Center.TextGui.Display.Text
        elseif resultTable.name == "Flag" then
            resultTable.message = model.Center.FortGui.FortName.Text
            resultTable.fortDecal = tonumber(model.ActualFlag["1"].TextureID:split('//')[2])
        end
        file.cost = file.cost + model:GetAttribute("Cost")
        table.insert(file.building, resultTable)
    end
    -- check if nothing saved
    if file.cost == 0 then
        return
    end
    -- check if there is a fort and place it first
    local index, table = findTable(file.building, 'name', 'Flag')
    if index then
        file.building[index] = file.building[1]
        file.building[1] = table
    end
    writefile(filePath, HttpService:JSONEncode(file))
end
function WaterlooModule:LoadStructureFromFile(filePath:string)
    local fileString = readfile(filePath)
    local decoded = HttpService:JSONDecode(fileString)
    return StructureModule.new(self, decoded.building, decoded.cost)
end

return WaterlooModule
