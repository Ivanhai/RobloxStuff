local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Inset = GuiService:GetGuiInset()

local function To3dSpace(pos)
	return Camera:ScreenPointToRay(pos.x, pos.y).Origin 
end


local function CalcSlope(vec)
	local rel = Camera.CFrame:pointToObjectSpace(vec)
	return Vector2.new(rel.x/-rel.z, rel.y/-rel.z)
end


local function Overlaps(cf, a1, a2)
	local rel = Camera.CFrame:ToObjectSpace(cf)
	local x, y = rel.x / -rel.z, rel.y / -rel.z

	return (a1.x) < x and x < (a2.x) 
		and (a1.y < y and y < a2.y) and rel.z < 0 
end


local function Swap(a1, a2)
	return Vector2.new(math.min(a1.x, a2.x), math.min(a1.y, a2.y)), Vector2.new(math.max(a1.x, a2.x), math.max(a1.y, a2.y))
end


local function Search(objs, p1, p2)
	local Found = {}
	local a1 = CalcSlope(p1)
	local a2 = CalcSlope(p2)

	a1, a2 = Swap(a1, a2)

	for _ ,obj in ipairs(objs) do

		local cf = obj:IsA("Model") and obj:GetBoundingBox() or obj.CFrame

		if Overlaps(cf,a1, a2) then
			table.insert(Found, obj)
		end
	end

	return Found
end

local SelectionBox = {}
SelectionBox.__index = SelectionBox
function SelectionBox.new(frame, filter)
	local new = setmetatable({
		Frame = frame,
		Filter = filter,
		Enabled = false,
		lastPos = Vector2.zero,
        Selected = {}
	}, SelectionBox)
	UserInputService.InputBegan:Connect(function(input)
		new:InputStarted(input)
	end)
	UserInputService.InputEnded:Connect(function(input)
		new:InputEnded(input)
	end)
	RunService.RenderStepped:Connect(function()
		new:Update()
	end)
	return new
end
function SelectionBox:SetEnabledState(state:boolean)
	self.Enabled = state
end
function SelectionBox:SetFilter(filter)
	self.Filter = filter
end
function SelectionBox:AddSelected(instance:Instance)
    if table.find(self.Selected, instance) then
        return
    end
    table.insert(self.Selected, instance)
    local box = Instance.new('SelectionBox')
    box.Adornee = instance
    box.Parent = instance
end
function SelectionBox:RemoveSelected(instance:Instance)
    local index = table.find(self.Selected, instance)
    if index then
        table.remove(self.Selected, index)
    end
    local box = instance:FindFirstChild('SelectionBox')
    if box then
        box:Destroy()
    end
end
function SelectionBox:UnselectAll()
    for _, instance in ipairs(self.Selected) do
        self:RemoveSelected(instance)
    end
end
function SelectionBox:Update()
	if self.Enabled then
		local Location = UserInputService:GetMouseLocation()
		local Size = Location - self.lastPos - Inset
		self.Frame.Size = UDim2.fromOffset(Size.X, Size.Y)
	end
end
function SelectionBox:InputStarted(input)
	if self.Enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		self.lastPos = Vector2.new(input.Position.X, input.Position.Y)
		self.Frame.Position = UDim2.fromOffset(self.lastPos.X, self.lastPos.Y)
		self.Frame.Visible = true
	end
end
function SelectionBox:InputEnded(input)
	if self.Enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		self.Frame.Visible = false
		local result = Search(self.Filter, To3dSpace(self.lastPos), To3dSpace(pos))
		for _, instance in ipairs(result) do
			if table.find(self.Selected, instance) then
				self:RemoveSelected(instance)
				continue
			end
            		self:AddSelected(instance)
       		end
	end
end

return SelectionBox
