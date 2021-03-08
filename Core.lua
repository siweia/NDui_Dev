local B, C, L, DB, F = unpack(NDui)

local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local GetFunctionCPUUsage = GetFunctionCPUUsage
local GetTime, GetAddOnCPUUsage = GetTime, GetAddOnCPUUsage
local sort, next, pairs, type = sort, next, pairs, type

local function createRoster(parent, i)
	local button = CreateFrame("Frame", nil, parent)
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
local function sortOptions(a, b)
	if a and b then
		if order then
			return a[sortBy] > b[sortBy]
		else
			return a[sortBy] < b[sortBy]
		end
	end
end

local function refreshAnchor()
	for i = 1, #f.options do
		local option = f.options[i]
		option[2]:ClearAllPoints()
		if i == 1 then
			option[2]:SetPoint("TOPLEFT", 5, 0)
		else
			option[2]:SetPoint("TOP", f.options[i-1][2], "BOTTOM")
		end
	end
end

local function updateFunctions()
	local loginTime = B:GetModule("Infobar").loginTime
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
		option[2].calls:SetText(floor(calls))
		option[2].cps:SetText(format("%.3f", cps))
		option[2].tpc:SetText(format("%.3f", tpc))
		option[2].usage:SetText(format("%.3f", usage))
		option[2].up:SetText(format("%.2f%%", up))
		option[4] = calls
		option[5] = cps
		option[6] = tpc
		option[7] = usage
		option[8] = up
	end
end

local function refresh()
	order = not order
	sort(f.options, sortOptions)
	updateFunctions()
end

local function onUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > 1 then
		sort(f.options, sortOptions)
		updateFunctions()
		refreshAnchor()

		self.elapsed = 0
	end
end

local function hehe()
	if f then f:Show() return end
	f = CreateFrame("Frame", nil, UIParent)
	f:SetSize(800, 510)
	f:SetPoint("CENTER")
	B.SetBD(f)
	B.CreateMF(f)

	f.close = CreateFrame("Button", nil, f)
	f.close:SetPoint("TOPRIGHT", f)
	f.close:SetScript("OnClick", function() f:Hide() end)

	f.Header = B.CreateFS(f, 13, "NDui Functions Static Panel", true, "TOPLEFT", 20, -10)
	f.Info = B.CreateFS(f, 13, "", false, "TOP", 0, -10)

	local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	scroll:SetSize(760, 450)
	scroll:SetPoint("BOTTOMLEFT", 10, 10)
	B.CreateBDFrame(scroll, .25)

	local roster = CreateFrame("Frame", nil, scroll)
	roster:SetAllPoints(scroll)
	roster:SetSize(760, 1)

	scroll:SetScrollChild(roster)

	local headers = {"FunctionName", "Calls", "Calls/sec", "Usage/calls", "Usage/sec", "Usage %"}
	local bu = {}
	for i, header in next, headers do
		bu[i] = CreateFrame("Button", nil, f)
		if i == 1 then
			bu[i]:SetSize(235 + 2*C.mult, 20)
			bu[i]:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", -C.mult, 2)
		else
			bu[i]:SetSize(100, 20)
			bu[i]:SetPoint("LEFT", bu[i-1], "RIGHT", 5, 0)
		end
		B.CreateBDFrame(bu[i])
		B.CreateFS(bu[i], 13, header)
		bu[i]:SetScript("OnClick", function()
			sortBy = i+2
			refresh()
			refreshAnchor()
		end)
	end

	local options = {}
	local i = 1
	for name1, module in pairs(B.Modules) do
		for name2, func in pairs(module) do
			if type(func) == "function" then
				options[i] = {}
				options[i][1] = func
				options[i][2] = createRoster(roster, name1..":"..name2)
				options[i][3] = name1..":"..name2
				if i == 1 then
					options[i][2]:SetPoint("TOPLEFT", 5, 0)
				else
					options[i][2]:SetPoint("TOP", options[i-1][2], "BOTTOM")
				end
				i = i + 1
			end
		end
	end
--[[
	for name, func in pairs(B) do
		if type(func) == "function" then
			options[i] = {}
			options[i][1] = func
			options[i][2] = createRoster(roster, "B:"..name)
			options[i][3] = "B:"..name
			if i == 1 then
				options[i][2]:SetPoint("TOPLEFT", 5, 0)
			else
				options[i][2]:SetPoint("TOP", options[i-1][2], "BOTTOM")
			end
			i = i + 1
		end
	end]]

	local cargBags = NDui.cargBags
	local bag = cargBags:GetImplementation("NDui_Backpack")
	if bag then
		local bagButton = bag:GetItemButtonClass()
		for name, func in pairs(bagButton) do
			if type(func) == "function" then
				options[i] = {}
				options[i][1] = func
				options[i][2] = createRoster(roster, "cargBags:"..name)
				options[i][3] = "CargBags:"..name
				if i == 1 then
					options[i][2]:SetPoint("TOPLEFT", 5, 0)
				else
					options[i][2]:SetPoint("TOP", options[i-1][2], "BOTTOM")
				end
				i = i + 1
			end
		end
	end

	f.options = options

	f:SetScript("OnUpdate", onUpdate)

	B.ReskinClose(f.close)
	B.ReskinScroll(scroll.ScrollBar)
end

SlashCmdList["NDUI_DEV_TOOL"] = hehe
SLASH_NDUI_DEV_TOOL1 = "/ndev"

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
		print("Open your map!")
		return
	end
	ChatFrame1:Clear()
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
				msg = msg .. "[" .. '"' .. twidth .. ":" .. theight .. ":" .. offsetx .. ":" .. offsety .. '"' .. "] = " .. '"'
				for fileData = 1, #filedataIDS do
					msg = msg .. filedataIDS[fileData]
					if fileData < #filedataIDS then
						msg = msg .. ", "
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