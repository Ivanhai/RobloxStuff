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
    table.remove(self.Selected, table.find(self.Selected, instance))
    local box = instance:FindFirstChild('SelectionBox')
    if box then
        box:Destroy()
    end
end
function SelectionBox:UnselectAll()
	-- table.remove causes all of the subsequent (following) array indices to be re-indexed every time you call it to remove an array entry
    local saved = table.clone(self.Selected)
    for _, instance in ipairs(saved) do
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
function SelectionBox:InputStarted(input:InputObject)
	if self.Enabled then
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.holdingControl then
            self.lastPos = UserInputService:GetMouseLocation()
		    self.Frame.Position = UDim2.fromOffset(self.lastPos.X, self.lastPos.Y)
		    self.Frame.Visible = true
        elseif input.KeyCode == Enum.KeyCode.LeftControl then
            self.holdingControl = true
        end
	end
end
function SelectionBox:InputEnded(input:InputObject)
	if self.Enabled then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = UserInputService:GetMouseLocation()
            if not self.holdingControl then
                self.Frame.Visible = false
                local result = Search(self.Filter, To3dSpace(self.lastPos), To3dSpace(pos))
                self:UnselectAll()
                for _, instance in ipairs(result) do
                    self:AddSelected(instance)
                end
                return
            end
            local unitray = Camera:ScreenPointToRay(pos.X, pos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Whitelist
            params.FilterDescendantsInstances = self.Filter
            local ray = workspace:Raycast(unitray.Origin, unitray.Direction * 10000, params)
            if not ray then return end
            local model = ray.Instance:FindFirstAncestorOfClass("Model")
			if table.find(self.Selected, model or ray.Instance) then
				self:RemoveSelected(model or ray.Instance)
			else
				self:AddSelected(model or ray.Instance)
			end
        elseif input.KeyCode == Enum.KeyCode.LeftControl then
            self.holdingControl = false
        end
	end
end

return SelectionBox
