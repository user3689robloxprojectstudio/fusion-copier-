-- =======================================================
-- FUSION GAME COPIER 2026
-- Better Lighting + Textures + Warning
-- =======================================================
local request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request) or (krnl and krnl.request)
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

if not request then
	warn("[!] Executor HTTP request function not available.")
	return
end

local SERVER_URL = "http://127.0.0.1:8080/"
local localPlayer = Players.LocalPlayer

local SERVICES_TO_DUMP = {
	game:GetService("Workspace"),
	game:GetService("ReplicatedStorage"),
	game:GetService("ServerScriptService"),
	game:GetService("ServerStorage"),
	game:GetService("StarterGui"),
	game:GetService("StarterPack"),
	game:GetService("StarterPlayer"),
	Lighting,
	game:GetService("SoundService"),
	game:GetService("ReplicatedFirst")
}

local IGNORED_CLASSES = {
	["BlurEffect"] = true,
	["DepthOfFieldEffect"] = true,
	["Sparkles"] = true,
	["ParticleEmitter"] = true,
	["Fire"] = true,
	["Smoke"] = true
}

local totalObjectsScanned = 0
local totalObjectsEstimate = 0

local XML_REPLACEMENTS = {
	["&"] = "&amp;",
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&quot;",
	["'"] = "&apos;"
}

local function escapeXml(str)
	if not str then return "" end
	return (tostring(str):gsub('[&<>"]', XML_REPLACEMENTS))
end

local function colorToUint8(c)
	local r = math.floor(c.R * 255 + 0.5)
	local g = math.floor(c.G * 255 + 0.5)
	local b = math.floor(c.B * 255 + 0.5)
	return 0xFF000000 + (r * 65536) + (g * 256) + b
end

local function serializeUDim2(name, udim2)
	return string.format('    <UDim2 name="%s"><XS>%f</XS><XO>%d</XO><YS>%f</YS><YO>%d</YO></UDim2>\n',
		name, udim2.X.Scale, udim2.X.Offset, udim2.Y.Scale, udim2.Y.Offset)
end

local function serializeUDim(name, udim)
	return string.format('    <UDim name="%s"><S>%f</S><O>%d</O></UDim>\n', name, udim.Scale, udim.Offset)
end

local function serializeVector2(name, vec2)
	return string.format('    <Vector2 name="%s"><X>%f</X><Y>%f</Y></Vector2>\n', name, vec2.X, vec2.Y)
end

local function serializeRect(name, rect)
	return string.format('    <Rect2D name="%s"><min><X>%d</X><Y>%d</Y></min><max><X>%d</X><Y>%d</Y></max></Rect2D>\n',
		name, rect.Min.X, rect.Min.Y, rect.Max.X, rect.Max.Y)
end

local function getScriptSource(scriptObj)
	local ok, src = pcall(function() return scriptObj.Source end)
	if ok and src and src ~= "" then return src end
	if decompile then
		local decompOk, decompSrc = pcall(function() return decompile(scriptObj) end)
		if decompOk and decompSrc then return decompSrc end
	end
	return "-- [Source protected or unreadable]"
end

local function serializeCFrame(cf)
	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
	return string.format([[
      <CoordinateFrame name="CFrame">
        <X>%f</X><Y>%f</Y><Z>%f</Z>
        <R00>%f</R00><R01>%f</R01><R02>%f</R02>
        <R10>%f</R10><R11>%f</R11><R12>%f</R12>
        <R20>%f</R20><R21>%f</R21><R22>%f</R22>
      </CoordinateFrame>
]], x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
end

local function serializePropertiesFast(inst, buffer)
	table.insert(buffer, "  <Properties>\n")
	table.insert(buffer, string.format('    <string name="Name">%s</string>\n', escapeXml(inst.Name)))

	-- ==================== LIGHTING ====================
	if inst:IsA("Lighting") then
		table.insert(buffer, string.format('    <float name="Brightness">%f</float>\n', inst.Brightness))
		table.insert(buffer, string.format('    <float name="Ambient">%f</float>\n', 0)) -- fallback
		table.insert(buffer, string.format('    <Color3uint8 name="Ambient">%d</Color3uint8>\n', colorToUint8(inst.Ambient)))
		table.insert(buffer, string.format('    <Color3uint8 name="OutdoorAmbient">%d</Color3uint8>\n', colorToUint8(inst.OutdoorAmbient)))
		table.insert(buffer, string.format('    <Color3uint8 name="ColorShift_Top">%d</Color3uint8>\n', colorToUint8(inst.ColorShift_Top)))
		table.insert(buffer, string.format('    <Color3uint8 name="ColorShift_Bottom">%d</Color3uint8>\n', colorToUint8(inst.ColorShift_Bottom)))
		table.insert(buffer, string.format('    <float name="GeographicLatitude">%f</float>\n', inst.GeographicLatitude))
		table.insert(buffer, string.format('    <float name="ClockTime">%f</float>\n', inst.ClockTime))
		table.insert(buffer, string.format('    <float name="TimeOfDay">%s</float>\n', tostring(inst.TimeOfDay)))
		table.insert(buffer, string.format('    <bool name="GlobalShadows">%s</bool>\n', inst.GlobalShadows and "true" or "false"))
		table.insert(buffer, string.format('    <float name="ExposureCompensation">%f</float>\n', inst.ExposureCompensation))
		table.insert(buffer, string.format('    <token name="Technology">%d</token>\n', inst.Technology.Value))
		table.insert(buffer, string.format('    <float name="EnvironmentDiffuseScale">%f</float>\n', inst.EnvironmentDiffuseScale))
		table.insert(buffer, string.format('    <float name="EnvironmentSpecularScale">%f</float>\n', inst.EnvironmentSpecularScale))
		table.insert(buffer, string.format('    <bool name="Outlines">%s</bool>\n', inst.Outlines and "true" or "false"))
	end

	if inst:IsA("Atmosphere") then
		table.insert(buffer, string.format('    <float name="Density">%f</float>\n', inst.Density))
		table.insert(buffer, string.format('    <float name="Offset">%f</float>\n', inst.Offset))
		table.insert(buffer, string.format('    <Color3uint8 name="Color">%d</Color3uint8>\n', colorToUint8(inst.Color)))
		table.insert(buffer, string.format('    <Color3uint8 name="Decay">%d</Color3uint8>\n', colorToUint8(inst.Decay)))
		table.insert(buffer, string.format('    <float name="Glare">%f</float>\n', inst.Glare))
		table.insert(buffer, string.format('    <float name="Haze">%f</float>\n', inst.Haze))
	end

	if inst:IsA("Sky") then
		table.insert(buffer, string.format('    <Content name="SkyboxBk"><url>%s</url></Content>\n', escapeXml(inst.SkyboxBk)))
		table.insert(buffer, string.format('    <Content name="SkyboxDn"><url>%s</url></Content>\n', escapeXml(inst.SkyboxDn)))
		table.insert(buffer, string.format('    <Content name="SkyboxFt"><url>%s</url></Content>\n', escapeXml(inst.SkyboxFt)))
		table.insert(buffer, string.format('    <Content name="SkyboxLf"><url>%s</url></Content>\n', escapeXml(inst.SkyboxLf)))
		table.insert(buffer, string.format('    <Content name="SkyboxRt"><url>%s</url></Content>\n', escapeXml(inst.SkyboxRt)))
		table.insert(buffer, string.format('    <Content name="SkyboxUp"><url>%s</url></Content>\n', escapeXml(inst.SkyboxUp)))
		table.insert(buffer, string.format('    <float name="StarCount">%f</float>\n', inst.StarCount))
		table.insert(buffer, string.format('    <float name="SunAngularSize">%f</float>\n', inst.SunAngularSize))
		table.insert(buffer, string.format('    <float name="MoonAngularSize">%f</float>\n', inst.MoonAngularSize))
	end

	if inst:IsA("ColorCorrectionEffect") or inst:IsA("BloomEffect") or inst:IsA("SunRaysEffect") or inst:IsA("BlurEffect") or inst:IsA("DepthOfFieldEffect") then
		table.insert(buffer, string.format('    <bool name="Enabled">%s</bool>\n', inst.Enabled and "true" or "false"))
		if inst:IsA("ColorCorrectionEffect") then
			table.insert(buffer, string.format('    <float name="Brightness">%f</float>\n', inst.Brightness))
			table.insert(buffer, string.format('    <float name="Contrast">%f</float>\n', inst.Contrast))
			table.insert(buffer, string.format('    <float name="Saturation">%f</float>\n', inst.Saturation))
			table.insert(buffer, string.format('    <Color3uint8 name="TintColor">%d</Color3uint8>\n', colorToUint8(inst.TintColor)))
		elseif inst:IsA("BloomEffect") then
			table.insert(buffer, string.format('    <float name="Intensity">%f</float>\n', inst.Intensity))
			table.insert(buffer, string.format('    <float name="Size">%f</float>\n', inst.Size))
			table.insert(buffer, string.format('    <float name="Threshold">%f</float>\n', inst.Threshold))
		elseif inst:IsA("SunRaysEffect") then
			table.insert(buffer, string.format('    <float name="Intensity">%f</float>\n', inst.Intensity))
			table.insert(buffer, string.format('    <float name="Spread">%f</float>\n', inst.Spread))
		end
	end

	-- ScreenGui etc
	if inst:IsA("ScreenGui") then
		table.insert(buffer, string.format('    <bool name="IgnoreGuiInset">%s</bool>\n', inst.IgnoreGuiInset and "true" or "false"))
		table.insert(buffer, string.format('    <int name="DisplayOrder">%d</int>\n', inst.DisplayOrder))
		table.insert(buffer, string.format('    <bool name="ResetOnSpawn">%s</bool>\n', inst.ResetOnSpawn and "true" or "false"))
		table.insert(buffer, string.format('    <token name="ZIndexBehavior">%d</token>\n', inst.ZIndexBehavior.Value))
	end

	if inst:IsA("LayerCollector") then
		table.insert(buffer, string.format('    <bool name="Enabled">%s</bool>\n', inst.Enabled and "true" or "false"))
		table.insert(buffer, string.format('    <bool name="ResetOnSpawn">%s</bool>\n', inst.ResetOnSpawn and "true" or "false"))
		table.insert(buffer, string.format('    <token name="ZIndexBehavior">%d</token>\n', inst.ZIndexBehavior.Value))
	end

	if inst:IsA("CanvasGroup") then
		table.insert(buffer, string.format('    <float name="GroupTransparency">%f</float>\n', inst.GroupTransparency))
		table.insert(buffer, string.format('    <Color3uint8 name="GroupColor3">%d</Color3uint8>\n', colorToUint8(inst.GroupColor3)))
	end

	if inst:IsA("SurfaceGui") or inst:IsA("BillboardGui") then
		table.insert(buffer, string.format('    <bool name="Enabled">%s</bool>\n', inst.Enabled and "true" or "false"))
		table.insert(buffer, string.format('    <bool name="AlwaysOnTop">%s</bool>\n', inst.AlwaysOnTop and "true" or "false"))
		if inst:IsA("BillboardGui") then
			table.insert(buffer, serializeUDim2("Size", inst.Size))
			table.insert(buffer, serializeVector2("ExtentsOffset", inst.ExtentsOffset))
		end
	end

	if inst:IsA("GuiObject") then
		table.insert(buffer, string.format('    <bool name="Visible">%s</bool>\n', inst.Visible and "true" or "false"))
		table.insert(buffer, string.format('    <bool name="ClipsDescendants">%s</bool>\n', inst.ClipsDescendants and "true" or "false"))
		table.insert(buffer, string.format('    <int name="ZIndex">%d</int>\n', inst.ZIndex))
		table.insert(buffer, string.format('    <int name="LayoutOrder">%d</int>\n', inst.LayoutOrder))
		table.insert(buffer, string.format('    <token name="AutomaticSize">%d</token>\n', inst.AutomaticSize.Value))
		table.insert(buffer, string.format('    <token name="SizeConstraint">%d</token>\n', inst.SizeConstraint.Value))
		table.insert(buffer, string.format('    <float name="BackgroundTransparency">%f</float>\n', inst.BackgroundTransparency))
		table.insert(buffer, string.format('    <float name="Rotation">%f</float>\n', inst.Rotation))
		table.insert(buffer, string.format('    <int name="BorderSizePixel">%d</int>\n', inst.BorderSizePixel))
		table.insert(buffer, string.format('    <Color3uint8 name="BackgroundColor3">%d</Color3uint8>\n', colorToUint8(inst.BackgroundColor3)))
		table.insert(buffer, string.format('    <Color3uint8 name="BorderColor3">%d</Color3uint8>\n', colorToUint8(inst.BorderColor3)))
		table.insert(buffer, serializeUDim2("Position", inst.Position))
		table.insert(buffer, serializeUDim2("Size", inst.Size))
		table.insert(buffer, serializeVector2("AnchorPoint", inst.AnchorPoint))
	end

	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		table.insert(buffer, string.format('    <string name="Text">%s</string>\n', escapeXml(inst.Text)))
		table.insert(buffer, string.format('    <float name="TextSize">%f</float>\n', inst.TextSize))
		table.insert(buffer, string.format('    <float name="TextTransparency">%f</float>\n', inst.TextTransparency))
		table.insert(buffer, string.format('    <bool name="TextScaled">%s</bool>\n', inst.TextScaled and "true" or "false"))
		table.insert(buffer, string.format('    <bool name="TextWrapped">%s</bool>\n', inst.TextWrapped and "true" or "false"))
		table.insert(buffer, string.format('    <bool name="RichText">%s</bool>\n', inst.RichText and "true" or "false"))
		table.insert(buffer, string.format('    <token name="Font">%d</token>\n', inst.Font.Value))
		table.insert(buffer, string.format('    <token name="TextXAlignment">%d</token>\n', inst.TextXAlignment.Value))
		table.insert(buffer, string.format('    <token name="TextYAlignment">%d</token>\n', inst.TextYAlignment.Value))
		table.insert(buffer, string.format('    <Color3uint8 name="TextColor3">%d</Color3uint8>\n', colorToUint8(inst.TextColor3)))
	end

	if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
		table.insert(buffer, string.format('    <Content name="Image"><url>%s</url></Content>\n', escapeXml(inst.Image)))
		table.insert(buffer, string.format('    <float name="ImageTransparency">%f</float>\n', inst.ImageTransparency))
		table.insert(buffer, string.format('    <Color3uint8 name="ImageColor3">%d</Color3uint8>\n', colorToUint8(inst.ImageColor3)))
		table.insert(buffer, string.format('    <token name="ScaleType">%d</token>\n', inst.ScaleType.Value))
		table.insert(buffer, string.format('    <float name="SliceScale">%f</float>\n', inst.SliceScale))
		table.insert(buffer, serializeRect("SliceCenter", inst.SliceCenter))
		table.insert(buffer, serializeVector2("ImageRectOffset", inst.ImageRectOffset))
		table.insert(buffer, serializeVector2("ImageRectSize", inst.ImageRectSize))
	end

	if inst:IsA("UICorner") then
		table.insert(buffer, serializeUDim("CornerRadius", inst.CornerRadius))
	end
	if inst:IsA("UIStroke") then
		table.insert(buffer, string.format('    <float name="Thickness">%f</float>\n', inst.Thickness))
		table.insert(buffer, string.format('    <float name="Transparency">%f</float>\n', inst.Transparency))
		table.insert(buffer, string.format('    <Color3uint8 name="Color">%d</Color3uint8>\n', colorToUint8(inst.Color)))
		table.insert(buffer, string.format('    <token name="ApplyStrokeMode">%d</token>\n', inst.ApplyStrokeMode.Value))
	end
	if inst:IsA("UIAspectRatioConstraint") then
		table.insert(buffer, string.format('    <float name="AspectRatio">%f</float>\n', inst.AspectRatio))
		table.insert(buffer, string.format('    <token name="AspectType">%d</token>\n', inst.AspectType.Value))
		table.insert(buffer, string.format('    <token name="DominantAxis">%d</token>\n', inst.DominantAxis.Value))
	end
	if inst:IsA("UISizeConstraint") then
		table.insert(buffer, serializeVector2("MinSize", inst.MinSize))
		table.insert(buffer, serializeVector2("MaxSize", inst.MaxSize))
	end
	if inst:IsA("UIPadding") then
		table.insert(buffer, serializeUDim("PaddingTop", inst.PaddingTop))
		table.insert(buffer, serializeUDim("PaddingBottom", inst.PaddingBottom))
		table.insert(buffer, serializeUDim("PaddingLeft", inst.PaddingLeft))
		table.insert(buffer, serializeUDim("PaddingRight", inst.PaddingRight))
	end
	if inst:IsA("UIGridLayout") or inst:IsA("UIListLayout") then
		table.insert(buffer, string.format('    <token name="SortOrder">%d</token>\n', inst.SortOrder.Value))
		table.insert(buffer, string.format('    <token name="FillDirection">%d</token>\n', inst.FillDirection.Value))
		if inst:IsA("UIGridLayout") then
			table.insert(buffer, serializeUDim2("CellSize", inst.CellSize))
			table.insert(buffer, serializeUDim2("CellPadding", inst.CellPadding))
		end
	end

	if inst:IsA("LuaSourceContainer") then
		local sourceText = getScriptSource(inst)
		table.insert(buffer, string.format('    <ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>\n', sourceText))
	end

	-- BasePart (strong version)
	if inst:IsA("BasePart") then
		table.insert(buffer, serializeCFrame(inst.CFrame))
		table.insert(buffer, string.format('    <Vector3 name="Size"><X>%f</X><Y>%f</Y><Z>%f</Z></Vector3>\n',
			inst.Size.X, inst.Size.Y, inst.Size.Z))
		table.insert(buffer, string.format('    <Vector3 name="Position"><X>%f</X><Y>%f</Y><Z>%f</Z></Vector3>\n',
			inst.Position.X, inst.Position.Y, inst.Position.Z))
		table.insert(buffer, '    <bool name="Anchored">true</bool>\n')
		table.insert(buffer, string.format('    <bool name="CanCollide">%s</bool>\n', inst.CanCollide and "true" or "false"))
		table.insert(buffer, string.format('    <float name="Transparency">%f</float>\n', inst.Transparency))
		table.insert(buffer, string.format('    <token name="Material">%d</token>\n', inst.Material.Value))
		table.insert(buffer, string.format('    <Color3uint8 name="Color">%d</Color3uint8>\n', colorToUint8(inst.Color)))
		table.insert(buffer, '    <Vector3 name="Velocity"><X>0</X><Y>0</Y><Z>0</Z></Vector3>\n')
		table.insert(buffer, '    <Vector3 name="RotVelocity"><X>0</X><Y>0</Y><Z>0</Z></Vector3>\n')
	end

	if inst:IsA("Part") then
		table.insert(buffer, string.format('    <token name="shape">%d</token>\n', inst.Shape.Value))
		table.insert(buffer, '    <token name="formFactorRaw">0</token>\n')
	end

	-- Stronger texture / mesh support
	if inst:IsA("MeshPart") then
		table.insert(buffer, string.format('    <Content name="MeshId"><url>%s</url></Content>\n', escapeXml(inst.MeshId)))
		table.insert(buffer, string.format('    <Content name="TextureID"><url>%s</url></Content>\n', escapeXml(inst.TextureID)))
	end

	if inst:IsA("SpecialMesh") then
		table.insert(buffer, string.format('    <Content name="MeshId"><url>%s</url></Content>\n', escapeXml(inst.MeshId)))
		table.insert(buffer, string.format('    <Content name="TextureId"><url>%s</url></Content>\n', escapeXml(inst.TextureId)))
		table.insert(buffer, string.format('    <Vector3 name="Scale"><X>%f</X><Y>%f</Y><Z>%f</Z></Vector3>\n',
			inst.Scale.X, inst.Scale.Y, inst.Scale.Z))
		table.insert(buffer, string.format('    <token name="MeshType">%d</token>\n', inst.MeshType.Value))
	end

	if inst:IsA("Decal") or inst:IsA("Texture") then
		table.insert(buffer, string.format('    <Content name="Texture"><url>%s</url></Content>\n', escapeXml(inst.Texture)))
		table.insert(buffer, string.format('    <float name="Transparency">%f</float>\n', inst.Transparency))
		table.insert(buffer, string.format('    <token name="Face">%d</token>\n', inst.Face.Value))
		if inst:IsA("Texture") then
			table.insert(buffer, string.format('    <float name="StudsPerTileU">%f</float>\n', inst.StudsPerTileU))
			table.insert(buffer, string.format('    <float name="StudsPerTileV">%f</float>\n', inst.StudsPerTileV))
		end
	end

	if inst:IsA("SurfaceAppearance") then
		table.insert(buffer, string.format('    <Content name="ColorMap"><url>%s</url></Content>\n', escapeXml(inst.ColorMap)))
		table.insert(buffer, string.format('    <Content name="MetalnessMap"><url>%s</url></Content>\n', escapeXml(inst.MetalnessMap)))
		table.insert(buffer, string.format('    <Content name="NormalMap"><url>%s</url></Content>\n', escapeXml(inst.NormalMap)))
		table.insert(buffer, string.format('    <Content name="RoughnessMap"><url>%s</url></Content>\n', escapeXml(inst.RoughnessMap)))
	end

	table.insert(buffer, "  </Properties>\n")
end

-- Fast yielding
local LAST_YIELD = os.clock()
local YIELD_EVERY_OBJECTS = 250
local YIELD_TIME = 0.045

local function serializeToXmlBuffer(inst, buffer, statusBtn, progressBar)
	if IGNORED_CLASSES[inst.ClassName] then return end

	totalObjectsScanned = totalObjectsScanned + 1

	if totalObjectsScanned % YIELD_EVERY_OBJECTS == 0 or (os.clock() - LAST_YIELD > YIELD_TIME) then
		local rawPercent = (totalObjectsScanned / math.max(totalObjectsEstimate, 1)) * 100
		local percentFormatted = string.format("%.1f", math.clamp(rawPercent, 0.1, 99.9))
		statusBtn.Text = string.format("%s%% (%d / %d)", percentFormatted, totalObjectsScanned, totalObjectsEstimate)
		progressBar.Size = UDim2.new(math.clamp(rawPercent / 100, 0, 1), 0, 1, 0)
		task.wait()
		LAST_YIELD = os.clock()
	end

	table.insert(buffer, string.format('<Item class="%s" referent="RBX_%d">\n', escapeXml(inst.ClassName), totalObjectsScanned))
	serializePropertiesFast(inst, buffer)

	for _, child in ipairs(inst:GetChildren()) do
		if not (child:IsA("Model") and Players:GetPlayerFromCharacter(child)) then
			serializeToXmlBuffer(child, buffer, statusBtn, progressBar)
		end
	end

	table.insert(buffer, "</Item>\n")
end

-- ==================== UI ====================
local guiName = "FusionCopier2026"
if CoreGui:FindFirstChild(guiName) then
	CoreGui[guiName]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.new(0, 360, 0, 260)
MainCard.Position = UDim2.new(0.05, 0, 0.35, 0)
MainCard.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
MainCard.BackgroundTransparency = 0.12
MainCard.Active = true
MainCard.Draggable = true
MainCard.ClipsDescendants = true
MainCard.Parent = ScreenGui

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 16)
CardCorner.Parent = MainCard

local CardStroke = Instance.new("UIStroke")
CardStroke.Color = Color3.fromRGB(99, 102, 241)
CardStroke.Thickness = 1.5
CardStroke.Transparency = 0.4
CardStroke.Parent = MainCard

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 32)
TitleLabel.Position = UDim2.new(0, 0, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FUSION COPIER 2026"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextColor3 = Color3.fromRGB(165, 180, 252)
TitleLabel.Parent = MainCard

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Size = UDim2.new(1, -20, 0, 18)
SubtitleLabel.Position = UDim2.new(0, 10, 0, 38)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "Lighting + Textures + Full Dump"
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextSize = 11
SubtitleLabel.TextColor3 = Color3.fromRGB(156, 163, 175)
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Parent = MainCard

-- WARNING BOX
local WarningFrame = Instance.new("Frame")
WarningFrame.Size = UDim2.new(0.92, 0, 0, 52)
WarningFrame.Position = UDim2.new(0.04, 0, 0, 62)
WarningFrame.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
WarningFrame.BorderSizePixel = 0
WarningFrame.Parent = MainCard

local WarningCorner = Instance.new("UICorner")
WarningCorner.CornerRadius = UDim.new(0, 8)
WarningCorner.Parent = WarningFrame

local WarningText = Instance.new("TextLabel")
WarningText.Size = UDim2.new(1, -12, 1, -8)
WarningText.Position = UDim2.new(0, 6, 0, 4)
WarningText.BackgroundTransparency = 1
WarningText.Text = "⚠ WARNING: Do NOT use this in games where pets / NPCs run around.\nOnly use in those games if you just want UI + scripts."
WarningText.Font = Enum.Font.Gotham
WarningText.TextSize = 11
WarningText.TextColor3 = Color3.fromRGB(255, 180, 180)
WarningText.TextWrapped = true
WarningText.TextXAlignment = Enum.TextXAlignment.Left
WarningText.TextYAlignment = Enum.TextYAlignment.Top
WarningText.Parent = WarningFrame

local ProgressBG = Instance.new("Frame")
ProgressBG.Size = UDim2.new(0.92, 0, 0, 6)
ProgressBG.Position = UDim2.new(0.04, 0, 0, 128)
ProgressBG.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
ProgressBG.Visible = false
ProgressBG.Parent = MainCard

local ProgressBGCorner = Instance.new("UICorner")
ProgressBGCorner.CornerRadius = UDim.new(0, 3)
ProgressBGCorner.Parent = ProgressBG

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
ProgressBar.Parent = ProgressBG

local ProgressBarCorner = Instance.new("UICorner")
ProgressBarCorner.CornerRadius = UDim.new(0, 3)
ProgressBarCorner.Parent = ProgressBar

local ActionBtn = Instance.new("TextButton")
ActionBtn.Size = UDim2.new(0.92, 0, 0, 42)
ActionBtn.Position = UDim2.new(0.04, 0, 0, 150)
ActionBtn.BackgroundColor3 = Color3.fromRGB(79, 70, 229)
ActionBtn.Text = "⚡ Boot Copier"
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 14
ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionBtn.Parent = MainCard

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 10)
BtnCorner.Parent = ActionBtn

local isBooted = false

ActionBtn.MouseButton1Click:Connect(function()
	if not isBooted then
		isBooted = true
		ActionBtn.Text = "Readying Engine..."
		TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 41, 59)}):Play()
		task.wait(0.2)
		ProgressBG.Visible = true
		ActionBtn.Text = "🚀 Export Complete Game & UI"
		TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(99, 102, 241)}):Play()
		return
	end

	totalObjectsScanned = 0
	totalObjectsEstimate = 0
	ActionBtn.Text = "Indexing Game & UI..."
	ProgressBar.Size = UDim2.new(0, 0, 1, 0)

	for _, s in ipairs(SERVICES_TO_DUMP) do
		pcall(function() totalObjectsEstimate = totalObjectsEstimate + #s:GetDescendants() end)
	end
	if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
		pcall(function() totalObjectsEstimate = totalObjectsEstimate + #localPlayer.PlayerGui:GetDescendants() end)
	end

	LAST_YIELD = os.clock()

	task.spawn(function()
		local xmlBuffer = {}
		table.insert(xmlBuffer, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n')
		table.insert(xmlBuffer, '  <External>null</External>\n  <External>nil</External>\n')

		for _, service in ipairs(SERVICES_TO_DUMP) do
			if service.Name == "StarterGui" then
				pcall(function()
					serializeToXmlBuffer(service, xmlBuffer, ActionBtn, ProgressBar)
				end)
				if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
					for _, activeGui in ipairs(localPlayer.PlayerGui:GetChildren()) do
						if activeGui.Name ~= guiName then
							pcall(function()
								serializeToXmlBuffer(activeGui, xmlBuffer, ActionBtn, ProgressBar)
							end)
						end
					end
				end
			else
				pcall(function()
					serializeToXmlBuffer(service, xmlBuffer, ActionBtn, ProgressBar)
				end)
			end
		end

		table.insert(xmlBuffer, '</roblox>')

		ActionBtn.Text = "Packaging Data..."
		ProgressBar.Size = UDim2.new(0.98, 0, 1, 0)

		local finalXml = table.concat(xmlBuffer)
		xmlBuffer = nil

		ActionBtn.Text = "Sending to Local Server..."
		local response = request({
			Url = SERVER_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/xml" },
			Body = finalXml
		})

		if response and (response.StatusCode == 200 or response.Success) then
			ActionBtn.Text = "✔ Complete Export Finished!"
			ProgressBar.Size = UDim2.new(1, 0, 1, 0)
			TweenService:Create(ActionBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(34, 197, 94)}):Play()
		else
			ActionBtn.Text = "❌ Connection Failed"
			TweenService:Create(ActionBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(239, 68, 68)}):Play()
		end

		task.wait(3)
		ProgressBar.Size = UDim2.new(0, 0, 1, 0)
		ActionBtn.Text = "🚀 Export Complete Game & UI"
		TweenService:Create(ActionBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(99, 102, 241)}):Play()
	end)
end)

print("[+] Fusion Copier 2026 Ready! (Lighting + Textures + Warning)")
