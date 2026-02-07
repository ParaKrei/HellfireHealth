--[[
	The settings menu, powered by Lugent's Menu System.
]]

local MENU = LugentMenu

local pages = {
	["mainMenu"] = 1,
	["skinList-client"] = 2,
	["skinEntry-client"] = 3,
	["skinAdd/Remove"] = 4,
	["adminMenu"] = 5,
	["adminTarget-single"] = 6,
	["adminTarget-all"] = 7,
	["skinList-server"] = 8,
	["skinEntry-server"] = 9
}

local mappings = {
	[2] = "doDeathJingle",
	[3] = "skin",
	[4] = "meltRing",
	[5] = "seeHealth",
	[6] = "presetNum",
	[7] = "autoSave",
	[9] = "disabled",
	[10] = "allowOnAllChars",
	[11] = "allowOnSpecialStages",
	[12] = "doRingSpill",
	[13] = "keepHealth",
	[14] = "fillOnly",
}
local mappings_admin = {
	[3] = "disabled",
	[4] = "allowOnAllChars",
	[5] = "allowOnSpecialStages",
	[6] = "doRingSpill",
	[7] = "keepHealth",
	[8] = "fillOnly",
	[10] = "adminLock",
}
local mappings_admin_all = {
	[2] = "disabled",
	[3] = "allowOnAllChars",
	[4] = "allowOnSpecialStages",
	[5] = "doRingSpill",
	[6] = "keepHealth",
	[7] = "fillOnly",
	[9] = "adminLock",
}
local cvar_mappings = {
	[7] = "hellfire_botEnable",
	[8] = "hellfire_allowBars",
	[9] = "hellfire_useSrvList",
	[11] = "hellfire_2011x",
	[12] = "hellfire_orangedemon",
}
local lastStored = {}
local lastStored_others = {}
local changes = {}

local skin_mode = 0 --"0" = add, "1" = remove
local targetSkin = ""
local getSkin = false
local admin_mode = false
local skin_mappings = {
	[3] = "isBanned",
	[4] = "shieldHack",
	[5] = "deathOverride",
	[6] = "noDeathJingle",
	[7] = "silentLoss",
}
local skin_server_mappings = {
	[3] = "serverBanned",
}
local skin_lastStored = {}
local skin_changes = {}

local targetPlayer = nil
local targeting_self = false
local message = ""

local function getCurrentSkin(menu)
	targetSkin = consoleplayer.mo.skin
	getSkin = true
end
local function applyClient()
	local order = {
		"doDeathJingle",
		"skin",
		"meltRing",
		"seeHealth",
		"autoSave",
		"disabled",
		"allowOnSpecialStages",
		"allowOnAllChars",
		"doRingSpill",
		"keepHealth",
		"fillOnly",
	}

	local las_enabled = false --This will probably get removed later.
	local lastAutoSave = consoleplayer.hellfireHealth.options.autoSave

	local cmdArgs = ""
	for i,key in ipairs(order) do
		local val = changes[key]
		cmdArgs = $+" "+tostring(val)
	end
	COM_BufInsertText(consoleplayer, "hf_set"+cmdArgs)

	if changes["presetNum"] ~= consoleplayer.hellfireHealth.options.presetNum then
		COM_BufInsertText(consoleplayer, "hellfire -s set hudpreset "..tostring(changes["presetNum"]))
	end

	CONS_Printf(consoleplayer, "Your settings have been applied.")
	if las_enabled and lastAutoSave and not(consoleplayer.hellfireHealth.options.autoSave) then
		CONS_Printf(consoleplayer, "Your personal settings have also been saved, as auto-save was on last time.")
	elseif consoleplayer.hellfireHealth.options.autoSave then
		CONS_Printf(consoleplayer, "Your personal settings have also been saved.")
	end
end
local function applyCVars()
	local order = {
		"hellfire_botEnable",
		"hellfire_allowBars",
		"hellfire_useSrvList",
		"hellfire_2011x",
		"hellfire_orangedemon",
	}

	for i,key in ipairs(order) do
		local val = changes[key]
		
		if val ~= CV_FindVar(key).value then
			COM_BufInsertText(consoleplayer, key+" "+tostring(val))
		end
	end

	CONS_Printf(consoleplayer, "Your settings have been applied.")
end
local function applyAdmin()
	local order = {
		"disabled",
		"allowOnSpecialStages",
		"allowOnAllChars",
		"doRingSpill",
		"keepHealth",
		"fillOnly",
		"adminLock",
		"maxHealth",
		"fillCap",
		"bypass",
	}
	local hasChanged = false

	local cmdArgs = ""
	for i,key in ipairs(order) do
		local val = changes[key]
		if targetPlayer.hellfireHealth.options[key] == nil then
			if key == "bypass" then
				val = changes["bypassServerList"]
				if val ~= targetPlayer.hellfireHealth["bypassServerList"] then
					hasChanged = true
				end
			elseif val ~= targetPlayer.hellfireHealth[key] then
				hasChanged = true
			end
		else
			if val ~= targetPlayer.hellfireHealth.options[key] then
				hasChanged = true
			end
		end
		
		cmdArgs = $+" "+tostring(val)
	end
	COM_BufInsertText(consoleplayer, "hf_adminset"+" "+targetPlayer.name+cmdArgs)

	if message ~= "" and hasChanged then
		CONS_Printf(targetPlayer, "\x85They also left you a message:\x82\n"..message)
	end

	CONS_Printf(consoleplayer, "Your settings have been applied.")

	--Go back to main admin page.
	MENU:GoToPage(pages["adminMenu"])
end
local function applyAdminAll()
	local order = {
		"disabled",
		"allowOnSpecialStages",
		"allowOnAllChars",
		"doRingSpill",
		"keepHealth",
		"fillOnly",
		"adminLock",
	}

	local cmdArgs = ""
	for i,key in ipairs(order) do
		local val = changes[key]
		
		cmdArgs = $+" "+tostring(val)
	end
	COM_BufInsertText(consoleplayer, "hf_adminsetall"+" "+cmdArgs)

	if changes["maxHealth"] ~= CV_FindVar("hellfire_maxHealth").value then
		COM_BufInsertText(consoleplayer, "hellfire_maxHealth "+tostring(changes["maxHealth"]))
	end
	if changes["fillCap"] ~= CV_FindVar("hellfire_fillCap").value then
		COM_BufInsertText(consoleplayer, "hellfire_fillCap "+tostring(changes["fillCap"]))
	end

	CONS_Printf(consoleplayer, "Your settings have been applied.")

	--Go back to main admin page.
	MENU:GoToPage(pages["adminMenu"])
end
local function openhudposGUI()
	if MENU.Page == pages["mainMenu"] then applyClient() end --Apply client settings before opening the GUI.

	COM_BufInsertText(consoleplayer, "hellfire set hudpos gui")

	MENU:CloseMenu()
end
local function resetTrackers()
	changes = {}
	message = ""
	MENU.Current[pages["adminTarget-single"]].entries[15].input = ""
	targetPlayer = nil
	lastStored = {}
	lastStored_others = {}
	
	targetSkin = ""
	skin_mode = 0
	skin_lastStored = {}
	skin_changes = {}

	for i=1,#MENU.Current[pages["adminTarget-all"]].entries do
		local entry = MENU.Current[pages["adminTarget-all"]].entries[i]

		entry.value = 1
	end
end

local function toAddPage(menu)
	skin_mode = 0
	menu[pages["skinAdd/Remove"]].header_text = "Hellfire Health - Add a skin"

	if admin_mode then
		menu[pages["skinAdd/Remove"]].previous_page = pages["skinList-server"]
	else
		menu[pages["skinAdd/Remove"]].previous_page = pages["skinList-client"]
	end

	MENU:GoToPage(pages["skinAdd/Remove"])
end
local function toRemovePage(menu)
	skin_mode = 1
	menu[pages["skinAdd/Remove"]].header_text = "Hellfire Health - Remove a skin"

	if admin_mode then
		menu[pages["skinAdd/Remove"]].previous_page = pages["skinList-server"]
	else
		menu[pages["skinAdd/Remove"]].previous_page = pages["skinList-client"]
	end

	MENU:GoToPage(pages["skinAdd/Remove"])
end
local function clientSkinEntry(menu, from)
	if from == nil then from = true end
	
	if from then targetSkin = menu[pages["skinList-client"]].entries[MENU.Cursor].text end
	menu[pages["skinEntry-client"]].header_text = "Hellfire Health - \""+targetSkin+"\" settings"

	MENU:GoToPage(pages["skinEntry-client"])
end
local function clientSkinList(menu, fromMain)
	if fromMain == nil then fromMain = true end
	
	local newEntries = {
		{text = "Add a skin", action = toAddPage, y_pos = 0},
		{text = "Remove a skin", action = toRemovePage, y_pos = 10},
		{text = "Refresh", action = clientSkinList, y_pos = 20},
		{header = true, text = "Saved skins", y_pos = 30},
	}
	local lastY = 32

	for skin in hf.pairsByKeys(hf.getClientList()) do
		lastY = $+10
		local entry = {text = skin, action = clientSkinEntry, y_pos = lastY}
		table.insert(newEntries, entry)
	end

	menu[pages["skinList-client"]].entries = newEntries

	if MENU.Page == pages["mainMenu"] then applyClient() end --Apply client settings before changing pages.

	if fromMain then MENU:GoToPage(pages["skinList-client"]) end
end
local function addSkinToClientList(menu, fromMain)
	if fromMain == nil then fromMain = true end

	local hasChanged = hf.modifyClientList(targetSkin, {isBanned=true})
	local changedStr = "has been added to the client skin list."
	local sameStr = "was already in the client skin list."

	if hasChanged then
		CONS_Printf(consoleplayer, "The skin \"\x82"..targetSkin.."\x80\" "..changedStr)
		consoleplayer.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
	else
		CONS_Printf(consoleplayer, "The skin \"\x82"..targetSkin.."\x80\" "..sameStr)
	end

	clientSkinEntry(menu, fromMain) --Go to the skin's entry
end
local function removeSkinFromClientList(menu, fromMain)
	if fromMain == nil then fromMain = true end

	local hasChanged = hf.modifyClientList(targetSkin, nil)
	local changedStr = "has been removed from the client skin list."
	local sameStr = "wasn't in the client skin list."

	if hasChanged then
		CONS_Printf(consoleplayer, "The skin \"\x82"..targetSkin.."\x80\" "..changedStr)
		consoleplayer.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
	else
		CONS_Printf(consoleplayer, "The skin \"\x82"..targetSkin.."\x80\" "..sameStr)
	end

	clientSkinList(menu) --Go back to skin list
end
local function serverSkinEntry(menu, from)
	if from == nil then from = true end
	
	if from then targetSkin = menu[pages["skinList-server"]].entries[MENU.Cursor].text end
	menu[pages["skinEntry-server"]].header_text = "Hellfire Health - \""+targetSkin+"\" settings"

	MENU:GoToPage(pages["skinEntry-server"])
end
local function serverSkinList(menu, fromMain)
	if fromMain == nil then fromMain = true end
	
	local newEntries = {
		{text = "Add a skin", action = toAddPage, y_pos = 0},
		{text = "Remove a skin", action = toRemovePage, y_pos = 10},
		{text = "Refresh", action = serverSkinList, y_pos = 20},
		{header = true, text = "Saved skins", y_pos = 30},
	}
	local lastY = 32

	for skin in hf.pairsByKeys(hf.srvList) do
		lastY = $+10
		local entry = {text = skin, action = serverSkinEntry, y_pos = lastY}
		table.insert(newEntries, entry)
	end

	menu[pages["skinList-server"]].entries = newEntries

	if fromMain then MENU:GoToPage(pages["skinList-server"]) end
end
local function addSkinToServerList(menu, fromMain)
	if fromMain == nil then fromMain = true end

	COM_BufInsertText(consoleplayer, "hf_serverList-new "+targetSkin)

	serverSkinEntry(menu, fromMain) --Go to the skin's entry
end
local function removeSkinFromServerList(menu, fromMain)
	if fromMain == nil then fromMain = true end

	COM_BufInsertText(consoleplayer, "hf_serverList-clear "+targetSkin)

	serverSkinList(menu) --Go back to skin list
end
local function changeSkinEntry(menu)
	if #menu[pages["skinAdd/Remove"]].entries[1].input == 0 then
		CONS_Printf(consoleplayer, "\x85You need to type something in!")
		return
	end

	targetSkin = menu[pages["skinAdd/Remove"]].entries[1].input
	menu[pages["skinAdd/Remove"]].entries[1].input = ""

	if skin_mode == 0 then
		if admin_mode then
			addSkinToServerList(menu, false)
		else
			addSkinToClientList(menu, false)
		end
	elseif skin_mode == 1 then
		if admin_mode then
			removeSkinFromServerList(menu, false)
		else
			removeSkinFromClientList(menu, false)
		end
	end
end
local function adminMenu(menu)
	if not(hf.isAdmin(consoleplayer)) then
		CONS_Printf(consoleplayer, "\x85You are NOT an admin!")
		return
	end

	if MENU.Page == pages["mainMenu"] then applyClient() end --Apply client settings before changing pages.

	admin_mode = true
	MENU:GoToPage(pages["adminMenu"])
end
local function adminPlayerSet(menu)
	if not(admin_mode) then
		CONS_Printf(consoleplayer, "\x85You are NOT an admin!")
		return
	end
	if MENU.Page == pages["adminMenu"] then applyCVars() end --Apply cvar changes before changing pages.

	targeting_self = false
	menu[pages["adminTarget-single"]].header_text = "Hellfire Health (Admin) - One player target"
	menu[pages["adminTarget-single"]].start_item = 1
	menu[pages["adminTarget-single"]].entries[1].player = 0

	resetTrackers()
	MENU:GoToPage(pages["adminTarget-single"])
end
local function adminSelfSet(menu)
	if not(admin_mode) then
		CONS_Printf(consoleplayer, "\x85You are NOT an admin!")
		return
	end
	if MENU.Page == pages["adminMenu"] then applyCVars() end --Apply cvar changes before changing pages.

	targeting_self = true
	menu[pages["adminTarget-single"]].header_text = "Hellfire Health (Admin) - Self target"
	menu[pages["adminTarget-single"]].start_item = 3
	menu[pages["adminTarget-single"]].entries[1].player = #consoleplayer

	resetTrackers()
	MENU:GoToPage(pages["adminTarget-single"])
end
local function adminAllSet(menu)
	if not(admin_mode) then
		CONS_Printf(consoleplayer, "\x85You are NOT an admin!")
		return
	end
	if MENU.Page == pages["adminMenu"] then applyCVars() end --Apply cvar changes before changing pages.

	resetTrackers()
	MENU:GoToPage(pages["adminTarget-all"])
end

local Settings = {
	{ --Main page
		x_pos = 30,
		y_pos = 30,
		header_text = "Hellfire Health - Settings Menu",
		header_color = V_YELLOWMAP,
		start_item = 2,
		previous_page = -1,
		previous_item = -1,
		no_background = false,
		scroll = false,
		entries = {
			{header = true, text = "Client preferences", y_pos = 0},
			{text = "Hear death jingle", options = {"False", "True"}, value = 2, y_pos = 12},
			{text = "UI skin", options = {"Red", "Yellow"}, value = 1, y_pos = 22},
			{text = "Melted ring", options = {"False", "True"}, value = 2, y_pos = 32},
			{text = "See health bars", options = {"False", "True"}, value = 2, y_pos = 42},
			{text = "Selected HUD preset", range = {1, 10}, value = 1, y_pos = 52},
			{text = "Auto save", options = {"False", "True"}, value = 2, y_pos = 62},
			{header = true, text = "Gameplay settings (only for you)", y_pos = 72},
			{text = "Disabled", options = {"False", "True"}, value = 1, y_pos = 84},
			{text = "Allow all characters", options = {"False", "True"}, value = 1, y_pos = 94},
			{text = "Allow on special stages", options = {"False", "True"}, value = 1, y_pos = 104},
			{text = "Use \"Ring Spill\" mode", options = {"False", "True"}, value = 1, y_pos = 114},
			{text = "Keep health between levels", options = {"False", "True"}, value = 1, y_pos = 124},
			{text = "Only heal if over fill cap", options = {"False", "True"}, value = 1, y_pos = 134},
			{text = "Personal skin settings list", action = clientSkinList, y_pos = 144},
			{text = "Open HUD positioning GUI (CLOSES MENU)", action = openhudposGUI, y_pos = 154},
			{text = "Admin menu", action = adminMenu, y_pos = 164},
		},
		on_open = function(menu, page)
			resetTrackers()
			admin_mode = false
		end,
		on_previous_page = function(menu, page)
			if admin_mode then applyCVars() end
			resetTrackers()
			admin_mode = false
		end,
		on_close = function(menu, page)
			applyClient()
			admin_mode = false
		end,
		thinker = function(menu, page)
			--Sync/save settings
			for i,name in pairs(mappings) do
				local opt = consoleplayer.hellfireHealth.options[name]
				
				if name == "skin" then
					if opt ~= lastStored[name] then
						if opt == "yellow" then page.entries[i].value = 2 else page.entries[i].value = 1 end
					end
					if page.entries[i].value == 2 then changes[name] = "yellow" else changes[name] = "red" end
				elseif name == "presetNum" then
					if opt ~= lastStored[name] and lastStored[name] ~= nil then
						page.entries[i].value = lastStored[name]
					end
					changes[name] = page.entries[i].value
				else
					if opt ~= lastStored[name] then
						if opt == true then page.entries[i].value = 2 else page.entries[i].value = 1 end
					end
					if page.entries[i].value == 2 then changes[name] = true else changes[name] = false end
				end
			end

			--Only allow the admin option if the player IS an admin.
			page.entries[17].invisible = not(hf.isAdmin(consoleplayer))
			page.entries[17].disabled = not(hf.isAdmin(consoleplayer))

			for i=8,14 do
				page.entries[i].disabled = consoleplayer.hellfireHealth.options.adminLock
			end

			lastStored = consoleplayer.hellfireHealth.options
		end,
		drawer = function(v, page)
			MENU:DrawScroll(v, page)

			--Add in an indicator to show if the player has adminLock on.
			if consoleplayer.hellfireHealth.options.adminLock then
				local colorMap = V_YELLOWMAP
				if leveltime % 17 < 8 then colorMap = V_REDMAP end

				v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), FixedDiv(43*FU, 2*FU), "An admin locked your gameplay settings!", colorMap, "thin-fixed-center")
			end

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Exit",
				"LEFT/RIGHT = Change entries",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Client skin list
		x_pos = 30,
		y_pos = 30,
		header_text = "Hellfire Health - YOUR skin settings list",
		header_color = V_YELLOWMAP,
		start_item = 1,
		previous_page = 1,
		previous_item = 2,
		no_background = false,
		scroll = false,
		entries = {}, --This is dynamically created!
		on_previous_page = function(menu, page)
			--Apply changes
			if #targetSkin > 0 then
				local hasChanged, wasRemoved = hf.modifyClientList(targetSkin, skin_changes)
				local changedStr = ""
				local sameStr = ""

				if wasRemoved then
					changedStr = "no longer has anything set for it, so it's entry has been completely removed."
					sameStr = "doesn't even have an entry."
				else
					changedStr = "has been updated."
					sameStr = "had no changes."
				end

				if hasChanged then
					CONS_Printf(consoleplayer, "Skin \"\x82"..targetSkin.."\x80\" "..changedStr)
					consoleplayer.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
				else
					CONS_Printf(consoleplayer, "Skin \"\x82"..targetSkin.."\x80\" "..sameStr)
				end
			end

			--Refresh lists
			clientSkinList(menu, false)

			resetTrackers()
		end,
		thinker = function(menu, page)
			--do nothing
		end,
		drawer = function(v, page)
			if #page.entries > 15 then MENU:DrawScroll(v, page) else MENU:DrawStandard(v, page) end

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Back",
				"LEFT/RIGHT = Change entries",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Client skin entry
		x_pos = 30,
		y_pos = 30,
		header_text = "",
		header_color = V_YELLOWMAP,
		start_item = 1,
		previous_page = 2,
		previous_item = 1,
		no_background = false,
		scroll = false,
		entries = {
			{text = "Delete this skin's entry", action = removeSkinFromClientList, y_pos = 0},
			{header = true, text = "Settings", y_pos = 10},
			{text = "Banned", options = {"False", "True"}, value = 1, y_pos = 22},
			{text = "Uses a shield hack", options = {"False", "True"}, value = 1, y_pos = 32},
			{text = "Has special death animations", options = {"False", "True"}, value = 1, y_pos = 42},
			{text = "No death jingle", options = {"False", "True"}, value = 1, y_pos = 52},
			{text = "No health loss sound", options = {"False", "True"}, value = 1, y_pos = 62},
		},
		thinker = function(menu, page)
			--Sync/save settings
			if hf.getClientList()[targetSkin] ~= nil then
				for i,name in pairs(skin_mappings) do
					local opt = hf.getClientList()[targetSkin][name]
					
					if opt ~= skin_lastStored[name] then
						if opt == true then page.entries[i].value = 2 else page.entries[i].value = 1 end
					end
					if page.entries[i].value == 2 then skin_changes[name] = true else skin_changes[name] = false end
				end

				skin_lastStored = hf.getClientList()[targetSkin]
			end
		end,
		drawer = function(v, page)
			MENU:DrawStandard(v, page)

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Back",
				"LEFT/RIGHT = Change entries",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Skin add/remove page
		x_pos = 30,
		y_pos = 30,
		header_text = "",
		header_color = V_YELLOWMAP,
		start_item = 1,
		previous_page = 2,
		previous_item = 1,
		no_background = false,
		scroll = false,
		entries = {
			{text = "Skin name:", input = "", y_pos = 0},
			{text = "Select current skin", action = getCurrentSkin, y_pos = 24},
			{text = "Confirm", action = changeSkinEntry, y_pos = 34},
		},
		thinker = function(menu, page)
			if getSkin then page.entries[1].input = targetSkin; getSkin = false end
		end,
		drawer = function(v, page)
			MENU:DrawStandard(v, page)

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Cancel",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Admin settings page
		x_pos = 30,
		y_pos = 30,
		header_text = "Hellfire Health (Admin) - Starting page",
		header_color = V_YELLOWMAP,
		start_item = 2,
		previous_page = 1,
		previous_item = 2,
		no_background = false,
		scroll = false,
		entries = {
			{header = true, text = "Who do you want to affect?", y_pos = 0},
			{text = "One person", action = adminPlayerSet, y_pos = 12},
			{text = "Everyone", action = adminAllSet, y_pos = 22},
			{text = "Yourself", action = adminSelfSet, y_pos = 32},
			{header = true, text = "Others", y_pos = 42},
			{text = "Server skin settings list", action = serverSkinList, y_pos = 54},
			{text = "Bots have health as well", options = {"False", "True"}, value = 1, y_pos = 64},
			{text = "3rd-person health bars", options = {"False", "True"}, value = 1, y_pos = 74},
			{text = "Use the server list", options = {"False", "True"}, value = 1, y_pos = 84},
			{header = true, text = "Compatibility Toggles", y_pos = 94},
			{text = "2011x", options = {"False", "True"}, value = 1, y_pos = 108},
			{text = "Orange Demon", options = {"False", "True"}, value = 1, y_pos = 118}
		},
		thinker = function(menu, page)
			for i,name in pairs(cvar_mappings) do
				local opt = CV_FindVar(name).value
				
				if opt ~= lastStored[name] then page.entries[i].value = opt+1 end
				changes[name] = page.entries[i].value-1

				lastStored[name] = opt
			end
		end,
		on_previous_page = function(menu, page)
			resetTrackers()
		end,
		drawer = function(v, page)
			MENU:DrawStandard(v, page)

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Back",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Admin single player change
		x_pos = 30,
		y_pos = 30,
		header_text = "Hellfire Health (Admin) - One player target",
		header_color = V_YELLOWMAP,
		start_item = 1,
		previous_page = 5,
		previous_item = 2,
		no_background = false,
		scroll = false,
		entries = {
			{text = "Target player", player = 0, y_pos = 0},
			{header = true, text = "Gameplay settings", y_pos = 10},
			{text = "Disabled", options = {"False", "True"}, value = 1, y_pos = 22},
			{text = "Allow all characters", options = {"False", "True"}, value = 1, y_pos = 32},
			{text = "Allow on special stages", options = {"False", "True"}, value = 1, y_pos = 42},
			{text = "Use \"Ring Spill\" mode", options = {"False", "True"}, value = 1, y_pos = 52},
			{text = "Keep health between levels", options = {"False", "True"}, value = 1, y_pos = 62},
			{text = "Only heal if over fill cap", options = {"False", "True"}, value = 1, y_pos = 72},
			{header = true, text = "Admin-only settings", y_pos = 82},
			{text = "Lock gameplay settings", options = {"False", "True"}, value = 1, y_pos = 94},
			{text = "Max health", range = {1, 50}, value = 5, y_pos = 104},
			{text = "Rings required for one hp", range = {1, 255}, value = 5, y_pos = 114},
			{text = "Bypass server list", options = {"False", "True"}, value = 1, y_pos = 124},
			{header = true, text = "", y_pos = 125},
			{text = "Message:", input = "", y_pos = 137},
			{text = "Apply changes", action = applyAdmin, y_pos = 161},
		},
		thinker = function(menu, page)
			message = page.entries[15].input
			if not(targeting_self) and players[page.entries[1].player] == consoleplayer then --Don't allow the admin to put in themselves in the non-yourself menu.
				if page.entries[1].player-1 > 0 and players[page.entries[1].player-1] ~= nil then page.entries[1].player = $-1
				elseif page.entries[1].player+1 < #players and players[page.entries[1].player+1] ~= nil then page.entries[1].player = $+1
				end
			end
			targetPlayer = players[page.entries[1].player]

			--Disable and hide message and targetPlayer fields if targeting self.
			page.entries[15].disabled = targeting_self
			page.entries[1].disabled = targeting_self
			page.entries[15].invisible = targeting_self
			page.entries[1].invisible = targeting_self

			-- Sync/save settings
			if targetPlayer ~= nil then
				for i,name in pairs(mappings_admin) do
					local opt = targetPlayer.hellfireHealth.options[name]
					
					if opt ~= lastStored[name] then
						if opt == true then page.entries[i].value = 2 else page.entries[i].value = 1 end
					end
					if page.entries[i].value == 2 then changes[name] = true else changes[name] = false end
				end

				local specialTbl = {
					[11]="maxHealth",
					[12]="fillCap",
					[13]="bypassServerList"
				}

				for i,name in pairs(specialTbl) do
					local opt = targetPlayer.hellfireHealth[name]
					
					if opt ~= lastStored_others[name] then
						if name ~= "bypassServerList" then
							page.entries[i].value = opt
						else
							if opt == true then page.entries[i].value = 2 else page.entries[i].value = 1 end
						end
					end

					if name ~= "bypassServerList" then
						changes[name] = page.entries[i].value
					else
						if page.entries[i].value == 2 then changes[name] = true else changes[name] = false end
					end
				end

				lastStored = targetPlayer.hellfireHealth.options
				lastStored_others = {
					["maxHealth"] = targetPlayer.hellfireHealth.maxHealth,
					["fillCap"] = targetPlayer.hellfireHealth.fillCap,
					["bypassServerList"] = targetPlayer.hellfireHealth.bypassServerList
				}
			end
		end,
		drawer = function(v, page)
			MENU:DrawScroll(v, page)

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Cancel",
				"LEFT/RIGHT = Change entries",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Admin everyone change
		x_pos = 30,
		y_pos = 30,
		header_text = "Hellfire Health (Admin) - Everyone",
		header_color = V_YELLOWMAP,
		start_item = 2,
		previous_page = 5,
		previous_item = 2,
		no_background = false,
		scroll = false,
		entries = {
			{header = true, text = "Gameplay settings", y_pos = 0},
			{text = "Disabled", options = {"Unset", "True", "False"}, value = 1, y_pos = 12},
			{text = "Allow all characters", options = {"Unset", "True", "False"}, value = 1, y_pos = 22},
			{text = "Allow on special stages", options = {"Unset", "True", "False"}, value = 1, y_pos = 32},
			{text = "Use \"Ring Spill\" mode", options = {"Unset", "True", "False"}, value = 1, y_pos = 42},
			{text = "Keep health between levels", options = {"Unset", "True", "False"}, value = 1, y_pos = 52},
			{text = "Only heal if over fill cap", options = {"Unset", "True", "False"}, value = 1, y_pos = 62},
			{header = true, text = "Admin-only settings", y_pos = 72},
			{text = "Lock gameplay settings", options = {"Unset", "True", "False"}, value = 1, y_pos = 84},
			{text = "Max health", range = {1, 50}, value = 5, y_pos = 94},
			{text = "Rings required for one hp", range = {1, 255}, value = 5, y_pos = 104},
			{header = true, text = "", y_pos = 105},
			{text = "Apply changes", action = applyAdminAll, y_pos = 117},
		},
		thinker = function(menu, page)
			-- Save settings
			for i,name in pairs(mappings_admin_all) do
				if page.entries[i].value == 1 then
					changes[name] = nil
				else
					if page.entries[i].value == 2 then changes[name] = true else changes[name] = false end
				end
			end
			
			if CV_FindVar("hellfire_maxHealth").value ~= lastStored["maxHealth"] then
				page.entries[10].value = CV_FindVar("hellfire_maxHealth").value
			end
			changes["maxHealth"] = page.entries[10].value

			if CV_FindVar("hellfire_fillCap").value ~= lastStored["fillCap"] then
				page.entries[11].value = CV_FindVar("hellfire_fillCap").value
			end
			changes["fillCap"] = page.entries[11].value

			lastStored = {["maxHealth"] = CV_FindVar("hellfire_maxHealth").value, ["fillCap"] = CV_FindVar("hellfire_fillCap").value}
		end,
		drawer = function(v, page)
			MENU:DrawStandard(v, page)

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Cancel",
				"LEFT/RIGHT = Change entries",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Server skin list
		x_pos = 30,
		y_pos = 30,
		header_text = "Hellfire Health - THE SERVER's skin settings list",
		header_color = V_YELLOWMAP,
		start_item = 1,
		previous_page = 5,
		previous_item = 2,
		no_background = false,
		scroll = false,
		entries = {}, --This is dynamically created!
		on_previous_page = function(menu, page)
			--Apply changes
			if #targetSkin > 0 then
				COM_BufInsertText(consoleplayer, "hf_serverList-change "+targetSkin+" "+tostring(skin_changes["serverBanned"]))
			end

			--Refresh lists
			serverSkinList(menu, false)

			resetTrackers()
		end,
		thinker = function(menu, page)
			--do nothing
		end,
		drawer = function(v, page)
			if #page.entries > 15 then MENU:DrawScroll(v, page) else MENU:DrawStandard(v, page) end

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Back",
				"LEFT/RIGHT = Change entries",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	},
	{ --Server skin entry
		x_pos = 30,
		y_pos = 30,
		header_text = "",
		header_color = V_YELLOWMAP,
		start_item = 1,
		previous_page = 8,
		previous_item = 1,
		no_background = false,
		scroll = false,
		entries = {
			{text = "Delete this skin's entry", action = removeSkinFromServerList, y_pos = 0},
			{header = true, text = "Settings", y_pos = 10},
			{text = "Banned", options = {"False", "True"}, value = 1, y_pos = 22}
		},
		thinker = function(menu, page)
			--Sync/save settings
			if hf.srvList[targetSkin] ~= nil then
				for i,name in pairs(skin_server_mappings) do
					local opt = hf.srvList[targetSkin][name]
					
					if opt ~= skin_lastStored[name] then
						if opt == true then page.entries[i].value = 2 else page.entries[i].value = 1 end
					end
					if page.entries[i].value == 2 then skin_changes[name] = true else skin_changes[name] = false end
				end

				skin_lastStored = hf.srvList[targetSkin]
			else
				--Entry doesn't exist yet.
				for i,name in pairs(skin_server_mappings) do
					if page.entries[i].value == 2 then skin_changes[name] = true else skin_changes[name] = false end
				end
			end
		end,
		drawer = function(v, page)
			MENU:DrawStandard(v, page)

			--Gotta add instructions on the controls!
			local instructions = {
				"ENTER = Activate",
				"ESCAPE = Back",
				"LEFT/RIGHT = Change entries",
				"UP/DOWN = Move cursor"
			}
			local text = table.concat(instructions, " | ")

			v.drawString(FixedDiv(300*FU, 2*FU)+(10*FU), 200*FU, text, V_YELLOWMAP|V_ALLOWLOWERCASE, "small-thin-fixed-center")
		end,
	}
}

COM_AddCommand("hellfire_menu", function(ply)
	MENU:OpenMenu(Settings, 1)
end, COM_LOCAL)