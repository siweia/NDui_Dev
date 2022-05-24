local _, ns = ...
local B, C, L, DB = unpack(NDui)

local f, INFO

local sort, next, pairs, type = sort, next, pairs, type
local floor, max, format = floor, max, format
local GetTime = GetTime
local IsShiftKeyDown = IsShiftKeyDown
local GetAddOnCPUUsage = GetAddOnCPUUsage
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local GetFunctionCPUUsage = GetFunctionCPUUsage
local HybridScrollFrame_GetOffset, HybridScrollFrame_Update = HybridScrollFrame_GetOffset, HybridScrollFrame_Update

function ns:CreateWidgetButton(parent, index)
	local button = CreateFrame("Frame", nil, parent)
	button:SetPoint("TOPLEFT", 0, - (index-1) *20)
	button:SetSize(750, 20)

	button.name = B.CreateFS(button, 13, i, false, "LEFT", 5, 0)

	button.calls = B.CreateFS(button, 13, "calls")
	button.calls:SetPoint("CENTER", button, "LEFT", 290, 0)

	button.cps = B.CreateFS(button, 13, "cps")
	button.cps:SetPoint("CENTER", button, "LEFT", 395, 0)

	button.tpc = B.CreateFS(button, 13, "tpc")
	button.tpc:SetPoint("CENTER", button, "LEFT", 500, 0)

	button.usage = B.CreateFS(button, 13, "usage")
	button.usage:SetPoint("CENTER", button, "LEFT", 605, 0)

	button.up = B.CreateFS(button, 13, "up")
	button.up:SetPoint("CENTER", button, "LEFT", 710, 0)

	return button
end

local sortBy = 3
local order

function ns.SortOptionValues(a, b)
	if a and b then
		if order then
			return a[sortBy] < b[sortBy]
		else
			return a[sortBy] > b[sortBy]
		end
	end
end

function ns:RefreshOptionValues()
	local loginTime = INFO.loginTime
	UpdateAddOnCPUUsage("NDui")

	local duration = GetTime() - loginTime + 1
	local numOptions = #f.options
	local fullUsage = GetAddOnCPUUsage("NDui")
	f.Info:SetFormattedText("Listed: %s    Usage: %.3fms    Usage/sec: %.3fms", numOptions, fullUsage, fullUsage/duration)

	for i = 1, numOptions do
		local option = f.options[i]
		local usage, calls = GetFunctionCPUUsage(option[1])
		local cps = calls/floor(duration)
		local tpc = usage/max(1, calls)
		local up = usage/max(1, fullUsage) * 100
		option[3] = calls
		option[4] = cps
		option[5] = tpc
		option[6] = usage
		option[7] = up
	end
end

function ns:UpdateWidgetButton(button)
	local index = button.index
	local option = f.options[index]

	button.name:SetText(option[2])
	button.calls:SetText(floor(option[3]))
	button.cps:SetText(format("%.3f", option[4]))
	button.tpc:SetText(format("%.3f", option[5]))
	button.usage:SetText(format("%.3f", option[6]))
	button.up:SetText(format("%.2f%%", option[7]))
end

function ns:UpdateWidgetFrame()
	local scrollFrame = f.scrollFrame
	local usedHeight = 0
	local buttons = scrollFrame.buttons
	local height = scrollFrame.buttonHeight
	local numOptions = #f.options
	local offset = HybridScrollFrame_GetOffset(scrollFrame)

	for i = 1, #buttons do
		local button = buttons[i]
		local index = offset + i
		if index <= numOptions then
			button.index = index
			ns:UpdateWidgetButton(button)
			usedHeight = usedHeight + height
			button:Show()
		else
			button.index = nil
			button:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, numOptions*height, usedHeight)
end

function ns:OptionsOnUpdate(elapsed)
	self.elapsed = (self.elapsed or 1) + elapsed
	if self.elapsed > 1 then
		ns:RefreshOptionValues()
		sort(f.options, ns.SortOptionValues)
		ns:UpdateWidgetFrame()

		self.elapsed = 0
	end
end

function ns:OnScrollChanged(delta)
	local scrollBar = self.scrollBar
	local step = delta*self.buttonHeight
	if IsShiftKeyDown() then
		step = step*22
	end
	scrollBar:SetValue(scrollBar:GetValue() - step)
	ns:UpdateWidgetFrame()
end

function ns:HeaderOnClick()
	sortBy = self.id + 1
	order = not order
	sort(f.options, ns.SortOptionValues)
	ns:UpdateWidgetFrame()
end

function ns:CreateDevFrame()
	if f then f:Show() return end

	f = CreateFrame("Frame", "NDuiDevFrame", UIParent)
	f:SetSize(800, 510)
	f:SetPoint("CENTER")
	B.SetBD(f)
	B.CreateMF(f)

	f.close = CreateFrame("Button", nil, f)
	f.close:SetPoint("TOPRIGHT", f)
	f.close:SetScript("OnClick", function() f:Hide() end)
	B.ReskinClose(f.close)

	f.Header = B.CreateFS(f, 13, "NDui Functions Static Panel", true, "TOPLEFT", 20, -10)
	f.Info = B.CreateFS(f, 13, "", false, "TOPRIGHT", -30, -10)

	local scrollFrame = CreateFrame("ScrollFrame", "NDuiDevFrameScrollFrame", f, "HybridScrollFrameTemplate")
	scrollFrame:SetSize(760, 450)
	scrollFrame:SetPoint("BOTTOMLEFT", 10, 10)
	B.CreateBDFrame(scrollFrame, .25)
	f.scrollFrame = scrollFrame

	local scrollBar = CreateFrame("Slider", "$parentScrollBar", scrollFrame, "HybridScrollBarTemplate")
	scrollBar.doNotHide = true
	B.ReskinScroll(scrollBar)
	scrollFrame.scrollBar = scrollBar

	local scrollChild = scrollFrame.scrollChild
	local numButtons = 23 + 1
	local buttonHeight = 20
	local buttons = {}
	for i = 1, numButtons do
		buttons[i] = ns:CreateWidgetButton(scrollChild, i)
	end

	scrollFrame.buttons = buttons
	scrollFrame.buttonHeight = buttonHeight
	scrollFrame.update = ns.UpdateWidgetFrame
	scrollFrame:SetScript("OnMouseWheel", ns.OnScrollChanged)
	scrollChild:SetSize(scrollFrame:GetWidth(), numButtons * buttonHeight)
	scrollFrame:SetVerticalScroll(0)
	scrollFrame:UpdateScrollChildRect()
	scrollBar:SetMinMaxValues(0, numButtons * buttonHeight)
	scrollBar:SetValue(0)

	local headers = {"FunctionName", "Calls", "Calls/sec", "Usage/calls", "Usage/sec", "Usage %"}
	local bu = {}
	for i, header in next, headers do
		bu[i] = CreateFrame("Button", nil, f)
		if i == 1 then
			bu[i]:SetSize(235 + 2*C.mult, 20)
			bu[i]:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", -C.mult, 2)
		else
			bu[i]:SetSize(100, 20)
			bu[i]:SetPoint("LEFT", bu[i-1], "RIGHT", 5, 0)
		end
		B.CreateBDFrame(bu[i])
		B.CreateFS(bu[i], 13, header)
		bu[i].id = i
		bu[i]:SetScript("OnClick", ns.HeaderOnClick)
	end

	local options = {}
	local i = 1
	for name1, module in pairs(B.Modules) do
		for name2, func in pairs(module) do
			if type(func) == "function" then
				options[i] = {}
				options[i][1] = func
				options[i][2] = name1..":"..name2
				i = i + 1
			end
		end
	end

	for name, func in pairs(B) do
		if type(func) == "function" then
			options[i] = {}
			options[i][1] = func
			options[i][2] = "B:"..name
			i = i + 1
		end
	end

	local cargBags = NDui.cargBags
	local bag = cargBags:GetImplementation("NDui_Backpack")
	if bag then
		local bagButton = bag:GetItemButtonClass()
		for name, func in pairs(bagButton) do
			if type(func) == "function" then
				options[i] = {}
				options[i][1] = func
				options[i][2] = "CargBags:"..name
				i = i + 1
			end
		end
	end

	f.options = options

	f:SetScript("OnUpdate", ns.OptionsOnUpdate)
end

SlashCmdList["NDUI_DEV_TOOL"] = ns.CreateDevFrame
SLASH_NDUI_DEV_TOOL1 = "/ndev"

function ns:UpdateDragCursor()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	px, py = px / scale, py / scale
	
	local angle = atan2(py - my, px - mx)
	local x, y, q = cos(angle), sin(angle), 1
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end

	local w = (Minimap:GetWidth() / 2) + 5
	local h = (Minimap:GetHeight() / 2) + 5
	local diagRadiusW = sqrt(2*(w)^2)-10
	local diagRadiusH = sqrt(2*(h)^2)-10
	x = max(-w, min(x*diagRadiusW, w))
	y = max(-h, min(y*diagRadiusH, h))

	self:ClearAllPoints()
	self:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function ns:ClickMinimapButton(btn)
	if btn == "LeftButton" then
		if f then
			f:Show()
		else
			ns:CreateDevFrame()
		end
	elseif btn == "RightButton" then
		if GetCVarBool("scriptProfile") then
			ResetCPUUsage()
			INFO.loginTime = GetTime()
		end
	end
end

function ns:CreateMinimapButton()
	local mmb = CreateFrame("Button", "NDuiDevMinimapButton", Minimap)
	mmb:SetPoint("BOTTOMLEFT", -15, 20)
	mmb:SetSize(32, 32)
	mmb:SetMovable(true)
	mmb:SetUserPlaced(true)
	mmb:RegisterForDrag("LeftButton")
	mmb:SetHighlightTexture(DB.chatLogo)
	mmb:GetHighlightTexture():SetSize(18, 9)
	mmb:GetHighlightTexture():ClearAllPoints()
	mmb:GetHighlightTexture():SetPoint("CENTER")

	local overlay = mmb:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
	overlay:SetPoint("TOPLEFT")

	local background = mmb:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
	background:SetPoint("TOPLEFT", 7, -5)

	local icon = mmb:CreateTexture(nil, "ARTWORK")
	icon:SetSize(22, 11)
	icon:SetPoint("CENTER")
	icon:SetTexture(DB.chatLogo)
	icon.__ignored = true -- ignore NDui recycle bin

	mmb:SetScript("OnEnter", function()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
		GameTooltip:SetOwner(mmb, "ANCHOR_LEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("NDuiDev", 1,1,1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("LeftButton: Toggle", .6,.8,1)
		GameTooltip:AddLine("RightButton: Reset", .6,.8,1)
		GameTooltip:Show()
	end)
	mmb:SetScript("OnLeave", GameTooltip_Hide)
	mmb:RegisterForClicks("AnyUp")
	mmb:SetScript("OnClick", ns.ClickMinimapButton)
	mmb:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", ns.UpdateDragCursor)
	end)
	mmb:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
end

B:RegisterEvent("PLAYER_LOGIN", function()
	INFO = B:GetModule("Infobar")
	ns:CreateMinimapButton()
end)

-- TalkingHeadFrame
do
	local talkingHeadTextureKitRegionFormatStrings = {
		["TextBackground"] = "%s-TextBackground",
		["Portrait"] = "%s-PortraitFrame",
	}
	local talkingHeadDefaultAtlases = {
		["TextBackground"] = "TalkingHeads-TextBackground",
		["Portrait"] = "TalkingHeads-Alliance-PortraitFrame",
	}
	local talkingHeadFontColor = {
		["TalkingHeads-Horde"] = {Name = CreateColor(0.28, 0.02, 0.02), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0)},
		["TalkingHeads-Alliance"] = {Name = CreateColor(0.02, 0.17, 0.33), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0)},
		["TalkingHeads-Neutral"] = {Name = CreateColor(0.33, 0.16, 0.02), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0)},
		["Normal"] = {Name = CreateColor(1, 0.82, 0.02), Text = CreateColor(1, 1, 1), Shadow = CreateColor(0.0, 0.0, 0.0, 1.0)},
	}

	--test
	function TestTalkingHead()
		LoadAddOn("Blizzard_TalkingHeadUI")
		local frame = TalkingHeadFrame;
		local model = frame.MainFrame.Model;

		if( frame.finishTimer ) then
			frame.finishTimer:Cancel();
			frame.finishTimer = nil;
		end
		if ( frame.voHandle ) then
			StopSound(frame.voHandle);
			frame.voHandle = nil;
		end

		local currentDisplayInfo = model:GetDisplayInfo();
		local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead, textureKitID

		displayInfo = 76291
		cameraID = 1240
		vo = 103175
		duration = 20.220001220703
		lineNumber = 0
		numLines = 4
		name = "Some Ugly Woman"
		text = "Testing this sheet out Testing this sheet out Testing this sheet out Testing this sheet out Testing this sheet out Testing this sheet out Testing this sheet out "
		isNewTalkingHead = true
		textureKitID = 0

		local textFormatted = string.format(text);
		if ( displayInfo and displayInfo ~= 0 ) then
			local textureKit;
			if ( textureKitID ~= 0 ) then
				SetupTextureKits(textureKitID, frame.BackgroundFrame, talkingHeadTextureKitRegionFormatStrings, false, true);
				SetupTextureKits(textureKitID, frame.PortraitFrame, talkingHeadTextureKitRegionFormatStrings, false, true);
				textureKit = GetUITextureKitInfo(textureKitID);
			else
				SetupAtlasesOnRegions(frame.BackgroundFrame, talkingHeadDefaultAtlases, true);
				SetupAtlasesOnRegions(frame.PortraitFrame, talkingHeadDefaultAtlases, true);
				textureKit = "Normal";
			end
			local nameColor = talkingHeadFontColor[textureKit].Name;
			local textColor = talkingHeadFontColor[textureKit].Text;
			local shadowColor = talkingHeadFontColor[textureKit].Shadow;
			frame.NameFrame.Name:SetTextColor(nameColor:GetRGB());
			frame.NameFrame.Name:SetShadowColor(shadowColor:GetRGBA());
			frame.TextFrame.Text:SetTextColor(textColor:GetRGB());
			frame.TextFrame.Text:SetShadowColor(shadowColor:GetRGBA());
			frame:Show();
			if ( currentDisplayInfo ~= displayInfo ) then
				model.uiCameraID = cameraID;
				model:SetDisplayInfo(displayInfo);
			else
				if ( model.uiCameraID ~= cameraID ) then
					model.uiCameraID = cameraID;
					Model_ApplyUICamera(model, model.uiCameraID);
				end
				TalkingHeadFrame_SetupAnimations(model);
			end

			if ( isNewTalkingHead ) then
				TalkingHeadFrame_Reset(frame, textFormatted, name);
				TalkingHeadFrame_FadeinFrames();
			else
				if ( name ~= frame.NameFrame.Name:GetText() ) then
					-- Fade out the old name and fade in the new name
					frame.NameFrame.Fadeout:Play();
					C_Timer.After(0.25, function()
						frame.NameFrame.Name:SetText(name);
					end);
					C_Timer.After(0.5, function()
						frame.NameFrame.Fadein:Play();
					end);

					frame.MainFrame.TalkingHeadsInAnim:Play();
				end

				if ( textFormatted ~= frame.TextFrame.Text:GetText() ) then
					-- Fade out the old text and fade in the new text
					frame.TextFrame.Fadeout:Play();
					C_Timer.After(0.25, function()
						frame.TextFrame.Text:SetText(textFormatted);
					end);
					C_Timer.After(0.5, function()
						frame.TextFrame.Fadein:Play();
					end);
				end
			end


			local success, voHandle = PlaySound(vo, "Talking Head", true, true);
			if ( success ) then
				frame.voHandle = voHandle;
			end
		end
	end
end

function TestMapRevel()
	if not WorldMapFrame:IsShown() then
		return
	end

	local msg = ""
	local mapID = WorldMapFrame.mapID
	local mapName = C_Map.GetMapInfo(mapID).name
	local mapArt = C_Map.GetMapArtID(mapID)
	msg = msg .. "--[[" .. mapName .. "]] [" .. mapArt .. "] = {"
	local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID);
	if exploredMapTextures then
		for i, exploredTextureInfo in ipairs(exploredMapTextures) do
			local twidth = exploredTextureInfo.textureWidth or 0
			if twidth > 0 then
				local theight = exploredTextureInfo.textureHeight or 0
				local offsetx = exploredTextureInfo.offsetX
				local offsety = exploredTextureInfo.offsetY
				local filedataIDS = exploredTextureInfo.fileDataIDs
				msg = msg .. "[" .. '"W' .. twidth .. ":H" .. theight .. ":X" .. offsetx .. ":Y" .. offsety .. '"' .. "] = " .. '"'
				for fileData = 1, #filedataIDS do
					msg = msg .. filedataIDS[fileData]
					if fileData < #filedataIDS then
						msg = msg .. ","
					else
						msg = msg .. '",'
						if i < #exploredMapTextures then
							msg = msg .. " "
						end
					end
				end
			end
		end
		msg = msg .. "},"
		print(msg)
	end
end