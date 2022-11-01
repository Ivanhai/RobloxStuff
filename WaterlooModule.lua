local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService('StarterGui')
local LocalPlayer = Players.LocalPlayer

local GetStructureModel:RemoteFunction = ReplicatedStorage.RemoteFunctions.GetStructureModel
local PlaceStructure = ReplicatedStorage.RemoteFunctions.PlaceStructure
local ShoutMessage = ReplicatedStorage.RemoteEvents.ShoutMessage
local SetFlagDecal = ReplicatedStorage.RemoteEvents.SetFlagDecal

local WaterlooModule = {}
local Center = Vector3.zero
local Relative = {}
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
function TeleportAndBuild(cframe, name, message, fortDecal):number
    local response = false
    getRoot(LocalPlayer.Character).CFrame = cframe
    while not response do
        response = PlaceStructure:InvokeServer(workspace.Terrain, Enum.Material.Sandstone, name, cframe)
        task.wait(.5)
    end
    if message then
        ShoutMessage:FireServer(message, WaterlooModule.createdStructure)
    elseif fortDecal then
        SetFlagDecal:FireServer(fortDecal)
    end
    return response
end
WaterlooModule.buildingPrices = {}
for _,instance in ipairs(LocalPlayer.PlayerGui.BuildGui.Backing:GetDescendants()) do
    if instance:IsA("ImageButton") then
        WaterlooModule.buildingPrices[instance.Name] = tonumber(instance:GetAttribute("Cost"):split(' ')[2])
    end
end
WaterlooModule.structureCache = {}
for structureName,_ in pairs(WaterlooModule.buildingPrices) do
    local model:Model = GetStructureModel:InvokeServer(structureName):Clone()
    model.Parent = nil
    WaterlooModule.structureCache[structureName] = model
end
workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and WaterlooModule.buildingPrices[child.Name] then
        WaterlooModule.selectedStructure = child
    end
end)
workspace.Structures.ChildAdded:Connect(function(child)
    if child:GetAttribute("OwnerName") == LocalPlayer.Name then
        WaterlooModule.createdStructure = child
    end
end)
function WaterlooModule:SaveStructureToFile(models, filePath)
    local file = {building = {}, cost = 0}
    for _, model in ipairs(models) do
        local resultTable = {
            name = model.Name,
            cost = 0
        }
        local PositionOffset = CFrame.new(0, self.structureCache[resultTable.name].PrimaryPart.CFrame.Position.Y / 2, 0)
        resultTable.cframe = EncodeCFrame(model.Center.CFrame:ToWorldSpace(PositionOffset))
        if resultTable.name == "DecalSign" then
            resultTable.message = model.Center.ImageGui.ImageLabel.Image:split('//')[2]
        elseif resultTable.name == "LargeSign" or resultTable.name == "SmallSign" or resultTable.name == "OverhangSign" then
            resultTable.message = model.Center.TextGui.Display.Text
        elseif resultTable.name == "Flag" then
            resultTable.message = model.Center.FortGui.FortName.Text
            resultTable.fortDecal = tonumber(model.ActualFlag["1"].TextureID:split('//')[2])
        end
        file.cost = file.cost + self.buildingPrices[resultTable.name]
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
    self.Structure = HttpService:JSONDecode(fileString)
end
function WaterlooModule:SpawnPreview()
    Center = Vector3.zero
    Relative = {}
    for _,structure in ipairs(self.Structure.building) do
        local model = WaterlooModule.structureCache[structure.name]:Clone()
        model:PivotTo(DecodeCFrame(structure.cframe))
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
                        instance.TextureId = "rbxassetid://"..structure.fortDecal
                    end
                end
            end
        end
        structure.Model = model
    end
    for _,structure in ipairs(self.Structure.building) do
        Center = Center + structure.Model.PrimaryPart.Position
    end
    Center = Center / #self.Structure.building
    for _, structure in ipairs(self.Structure.building) do
	    Relative[structure.Model] = structure.Model.PrimaryPart.Position - Center
    end
end
function WaterlooModule:MovePreview(newPos:Vector3)
    for Model, RelativePosition in pairs(Relative) do
        local cframe = CFrame.new(newPos + RelativePosition) * CFrame.Angles(Model.PrimaryPart.CFrame:ToOrientation())
        Model:PivotTo(cframe)
    end
end
function WaterlooModule:DestroyPreview()
    for _, structure in ipairs(self.Structure.building) do
        structure.Model:Destroy()
    end
end
function WaterlooModule:HidePreview()
    for _,structure in ipairs(self.Structure.building) do
        structure.Model.Parent = nil
    end
end
function WaterlooModule:BuildStructure()
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
    for _,structure in ipairs(self.Structure.building) do
        cframe = structure.Model.PrimaryPart.CFrame
        local newTokens = TeleportAndBuild(cframe, structure.name, structure.message, structure.fortDecal)
        LocalPlayer.PlayerGui.BuildGui.Backing.Tokens.Text = "Materials: "..newTokens
        structure.Model:Destroy()
    end
    unfloat()
    connection:Disconnect()
end

return WaterlooModule
