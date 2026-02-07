--[[
	EVERYTHING related to the console (commands and cvars) live here.
]]

local helpTxt = [[
======================================================
]]..'\x85Hellfire Saga\x80 health system command arguments:\n'..[[
======================================================
]]..'"\x82set\x80"'..[[ = Set variables for ONLY yourself.
EXAMPLE: "hellfire set disablesystem true".
You can fetch the available variables with "help" ("hellfire set help").
------------------------------------------------------
]]..'"\x82get\x80"'..[[ = Get variables, usually used to get the skin lists.
EXAMPLE: "hellfire get clientlist".
You can fetch the available variables with "list" ("hellfire get list").
------------------------------------------------------
]]..'"\x82\fadd\x80"'..[[ = Add entries to a list, usually used for the skin lists.
EXAMPLE: "hellfire add bannedskins tails".
You can fetch the available lists with "list" ("hellfire add list").
------------------------------------------------------
]]..'"\x82\fremove\x80"'..[[ = Removes entries from a list, usually used for the skin lists.
EXAMPLE: "hellfire remove bannedskins tails".
You can fetch the available lists with "list" ("hellfire remove list").
------------------------------------------------------
]]..'"\x82\fsave\x80"'..[[ = Manually save your preferences.
------------------------------------------------------
]]..'"\x82\freload\x80"'..[[ = Reload any changes made to your preferences.
------------------------------------------------------
]]..'"\x82\bdisable\x80"'..[[ = Shortcut to ]]..'"\x82set disablesystem true\x80"'..[[.
------------------------------------------------------
]]..'"\x82\benable\x80"'..[[ = Shortcut to ]]..'"\x82set disablesystem false\x80"'..[[.
------------------------------------------------------
]]..'"\x82\bspillmode\x80"'..[[ = Shortcut toggle for ]]..'"\x82set ringspill\x80"'..[[.
------------------------------------------------------
]]..'"\x82\bhelp\x80"'..[[ = Prints out this message.
]]

local varList_Intro = "\x8C\bAvailable variables:\x80\n"
local varList_Client = [[
]].."\"\x82\bdeathjingle\x80\""..[[ = Sets if the death jingle should be enabled; [either: true or false].
]].."\x85"..[[This setting is affected by auto-save!]].."\x80"..[[
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bskin\x80\""..[[ = Sets the color of the rings and \"HP\" text;
[either: red/r or yellow/y; not case-sensitive].
]].."\x85"..[[This setting is affected by auto-save!]].."\x80"..[[
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bmeltring\x80\""..[[ = Sets if the main/last ring is melted or not;
[either: true or false].
]].."\x85"..[[This setting is affected by auto-save!]].."\x80"..[[
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bhealthbars\x80\""..[[ = Set if you can see the health bars above players;
[either: true or false].
]].."\x85"..[[This setting is affected by auto-save!]].."\x80"..[[
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bautosave\x80\""..[[ = Set if your preferences will save for you;
[either: true or false].
]].."\x85"..[[This setting is affected by auto-save (but it checks the last setting it was on)!]].."\x80"..[[
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bhudpos\x80\""..[[ = Sets the STARTING position of the HUD.
This command has it's own help command, call it with ]].."\"\x85\bhellfire set hudpos help\x80\""..[[!
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bhudpreset\x80\""..[[ = Sets what HUD position preset is used; [range: 1-10].
-------------------------------------------------------------------------------------------------------
]]
local varList = [[
]].."\"\x82\bspecialstages\x80\""..[[ = Sets if the health system works in special stages;
(NiGHTs stages, multiplayer special stages, etc.) [either: true or false].
-------------------------------------------------------------------------------------------------------
]].."\"\x82\ballchars\x80\""..[[ = Sets if the health system works with all characters;
(allows usage on characters like Takis and Samus) [either: true or false].
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bringspill\x80\""..[[ = Enables a unique system that allows ring spills,
but upon ring loss, you will enter a ring deficit that increases with how much health you've lost.
In order to gain health again, you must get the ring deficit back to zero,
there is a counter below the health plate that shows your current ring deficit [either: true or false].
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bkeephp\x80\""..[[ = Sets if the health system keeps the states progress on all rings between levels;
[either: true or false].
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bfillonly\x80\""..[[ = Sets if health can only be gained through anything that increases your ring count
over your fill cap instantly;
[either: true or false].
-------------------------------------------------------------------------------------------------------
]].."\"\x82\badminlock\x80\""..[[ = Sets if the targeted player can change their gameplay settings,
administrator only, as the name implies;
[either: true or false].
-------------------------------------------------------------------------------------------------------
]].."\"\x82\bdisablesystem\x80\""..[[ = Sets if the system should be enabled;
it's name is pretty self-explanatory [either: true or false].)
]]

local listTxt = [[
]].."\"\x82\abannedskins\x80\""..[[ (characters that aren't allowed to use the health system)
]].."\"\x82specialdeath\x80\""..[[ (characters with unique deaths)
]].."\"\x82shieldhack\x80\""..[[ (characters that use a shield in a hacky way, e.g. Mario Bros.)
]].."\"\x82nojingle\x80\""..[[ (characters in this list won't play the death jingle)
]].."\"\x82silentloss\x80\""..[[ (characters in this list won't play the health ring loss sound)
]]

local hudposHelpTxt = [[
======================================================
]]..'\x85hudpos\x80 command arguments:\n'..[[
======================================================
]]..'"\x82gui\x80"'..[[ = Opens the GUI to help position the HUD with mouse support.
EXAMPLE: "hellfire set hudpos gui".
------------------------------------------------------
]]..'"\x82x, y, presetNum\x80"'..[[ = The X and Y position (on your screen)
the HUD's new STARTING position is, followed by the preset to override.
EXAMPLE: "hellfire set hudpos 0 0 2".
------------------------------------------------------
]]..'"\x82reload\x80"'..[[ = Reloads your HUD presets.
EXAMPLE: "hellfire set hudpos reload".
------------------------------------------------------
]]..'"\x82\bhelp\x80"'..[[ = Prints out this message.
------------------------------------------------------
]]..'\x85\bNOTE:'..[[ Both the GUI and command methods of setting the HUD position will auto-save any changes!
]]

--Quick function to change the client list.
local function changeList(isAdmin, ply, skin, remove, var, listStr)
	if not(isAdmin) then
		local hasChanged, wasRemoved = hf.modifyClientList(skin:lower(), {[var]=not(remove)})
		local changedStr = ""
		local sameStr = ""

		if remove then
			if wasRemoved then
				changedStr = "no longer has anything set for it, so it's entry has been completely removed."
				sameStr = "doesn't even have an entry."
			else
				changedStr = "has been removed from the "..listStr.." list."
				sameStr = "wasn't in the "..listStr.." list."
			end
		else
			changedStr = "has been added to the "..listStr.." list."
			sameStr = "was already in the "..listStr.." list."
		end

		if hasChanged then
			CONS_Printf(ply, "Skin \"\x82"..skin:lower().."\x80\" "..changedStr)
			ply.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
		else
			CONS_Printf(ply, "Skin \"\x82"..skin:lower().."\x80\" "..sameStr)
		end
	else
		CONS_Printf(ply, "Please use the non-admin command to set this.")
	end
end

--Quick function to change the client preferences.
local function setClientVar(isAdmin, ply, args, silent, onlyChanged)
	if not(isAdmin) then
		local lastAutoSave = ply.hellfireHealth.options.autoSave

		if args[1]:lower() == "bool" then
			hf.set_hellfireBoolVar(ply, args[2], args[3]:lower(), args[4], silent, onlyChanged)
		elseif args[1]:lower() == "str" then
			hf.set_hellfireStrVar(ply, args[2], args[3]:lower(), args[5], args[6], args[4], silent, onlyChanged)
		end

		if args[2] == "autoSave" then
			if lastAutoSave then
				if not(silent) then CONS_Printf(ply, "Saving your settings (you had auto-saving on before you changed it)...") end
				hf.savePrefs(ply.hellfireHealth)
			end
		else
			if ply.hellfireHealth.options.autoSave then
				if not(silent) then CONS_Printf(ply, "Saving your settings...") end
				hf.savePrefs(ply.hellfireHealth)
			end
		end
	else
		if not(silent) then CONS_Printf(ply, "Please use the non-admin command to set this.") end
	end
end

--Quick function to set the sensitive variables.
local function setSensVar(isAdmin, ply, args, silent, onlyChanged)
	local adminTxt = "\x8B\bAdministrator \x86"..ply.name.."\x80 has "
	local selfTarget = ply.name:lower() == args[4]:lower()
	local wasValid = false
	
	if isAdmin then
		if args[4] ~= "" then
			for target in players.iterate() do
				if target.name:lower() == args[4]:lower() then
					local statements = {
						adminTxt..args[3][1].trueStatement.." for you and only you.",
						adminTxt..args[3][1].falseStatement.." for you and only you."
					}
					if selfTarget then
						statements = {
							"\x86You\x80 "..args[3][1].trueStatement.." for yourself.",
							"\x86You\x80 "..args[3][1].falseStatement.." for yourself."
						}
					end
					
					local noChange = hf.set_hellfireBoolVar(target, args[1], args[2]:lower(), {
						trueStatement=statements[1], falseStatement=statements[2]
					}, false, onlyChanged)
					
					if args[5] ~= "" and (onlyChanged and not(noChange)) and not(selfTarget) then
						CONS_Printf(target, "\x85They also left you a message:\x82\n"..args[5])
					end

					if not(silent) then
						if onlyChanged and noChange then return end
						if selfTarget then return end
						CONS_Printf(ply, "You set \x85"..args[4].."\x80\b's "..string.format(args[3][2], args[2]:lower()))
					end

					return
				end
			end

			CONS_Printf(ply, "\x85There is no player named \"\x82"..args[4].."\x85\"!")
		else
			for target in players.iterate() do
				local val1, val2 = hf.set_hellfireBoolVar(target, args[1], args[2]:lower(), {
					trueStatement=adminTxt..args[3][1].trueStatement..".",
					falseStatement=adminTxt..args[3][1].falseStatement.."."
				}, false, onlyChanged)

				wasValid = val2
			end

			if not(silent) and wasValid then CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's "..string.format(args[3][2], args[2]:lower())) end
		end
	else
		hf.set_hellfireBoolVar(ply, args[1], args[2]:lower(), args[3][3], silent, onlyChanged)
	end
end

local function hfCMD(isAdmin, ply, args)
	--Organize the arguments
	local silent = false
	local onlyChanged = false
	for i=1,#args+1 do if args[i] == nil then args[i] = "" end end --The switch function doesn't like nils.
	hf.switch(args[1]:lower())
		.case("--silent", "-s")
		.case("-s", function()
			silent = true
			table.remove(args, 1)
		end)
		.case("--onlychanged", "-oc")
		.case("-oc", function()
			onlyChanged = true
			table.remove(args, 1)
		end)
		.process()

	--Start the actual code
	hf.switch(args[1]:lower())
		.case("set", function()
			hf.switch(args[2]:lower())
				.case("deathjingle", function()
					setClientVar(isAdmin, ply, {"bool", "doDeathJingle", args[3]:lower(), {
						trueStatement="The \x85Hellfire Saga\x80 death jingle is now \x82\benabled\x80.",
						falseStatement="The \x85Hellfire Saga\x80 death jingle is now \x82\bdisabled\x80."
					}}, silent, onlyChanged)
				end)
				.case("skin", function()
					setClientVar(isAdmin, ply, {"str", "skin", args[3]:lower(), {
						statement1="The \x85Hellfire Saga\x80 now uses the color \x82\bred\x80.",
						statement2="The \x85Hellfire Saga\x80 now uses the color \x82\byellow\x80."
					}, {returnVal="red", values={"red", "r"}}, {returnVal="yellow", values={"yellow", "y"}}}, silent, onlyChanged)
				end)
				.case("meltring", function()
					setClientVar(isAdmin, ply, {"bool", "meltRing", args[3]:lower(), {
						trueStatement="The main ring now uses the \x82\bmelted\x80 version.",
						falseStatement="The main ring now uses the \x82\bnon-melted\x80 version."
					}}, silent, onlyChanged)
				end)
				.case("healthbars", function()
					setClientVar(isAdmin, ply, {"bool", "seeHealth", args[3]:lower(), {
						trueStatement="Health bar visibility \x85(for you)\x80 is now \x82\benabled\x80.",
						falseStatement="Health bar visibility \x85(for you)\x80 is now \x82\bdisabled\x80."
					}}, silent, onlyChanged)
				end)
				.case("autosave", function()
					setClientVar(isAdmin, ply, {"bool", "autoSave", args[3]:lower(), {
						trueStatement="Auto-saving is now \x82\benabled\x80.",
						falseStatement="Auto-saving is now \x82\bdisabled\x80."
					}}, silent, onlyChanged)
				end)
				.case("hudpos", function()
					if not(isAdmin) then
						hf.switch(args[3]:lower())
							.case("gui", function()
								ply.hellfireHealth.hudposGUI.visible = true
								ply.hellfireHealth.hudposGUI.ogPresetNum = ply.hellfireHealth.options.presetNum
								ply.hellfireHealth.hudposGUI.lockedCamAngles = {
									angleturn = ply.cmd.angleturn,
									aiming = ply.cmd.aiming
								}
								hf.resetRings(ply.hellfireHealth, ply.hellfireHealth.hudposGUI.previewRingCount)
							end)
							.case("reload", function()
								if not(silent) then CONS_Printf(ply, "\x85Reloading your HUD presets!") end
								hf.loadHUDPreset(ply)
							end)
							.case("help", function()
								CONS_Printf(ply, hudposHelpTxt)
							end)
							.case("", function()
								CONS_Printf(ply, "\x85\bCan\'t do anything with this lack of information! If you need help, type in \"\x82hellfire hudpos help\x80\"!")
							end)
							.default(function()
								if tonumber(args[3]) == nil then
									CONS_Printf(ply, '\x85"'..args[3]..'"'.." is NOT a number or is \"gui\"!")
								else
									if args[4] ~= "" then
										if tonumber(args[4]) ~= nil then
											if args[5] ~= "" then
												if tonumber(args[5]) ~= nil then
													if tonumber(args[5]) >= 1 and tonumber(args[5]) <= 10 then
														local newPos = {x=tonumber(args[3]), y=tonumber(args[4])}
														hf.modifyHUDPresets(tonumber(args[5]), newPos)
														CONS_Printf(ply, "\bPreset #\x82"..args[5].."\x80 has been set to the coordinates: \x82"..args[3].."\x80, \x82"..args[4].."\x80.")
														hf.loadHUDPreset(ply)
													else
														CONS_Printf(ply, '\x85"'..args[5]..'"'.." is out of range!")
													end
												else
													CONS_Printf(ply, '\x85"'..args[5]..'"'.." is NOT a number!")
												end
											else
												CONS_Printf(ply, "\x85The preset number is missing!")
											end
										else
											CONS_Printf(ply, '\x85"'..args[4]..'"'.." is NOT a number!")
										end
									else
										CONS_Printf(ply, "\x85The Y position is missing!")
									end
								end
							end)
							.process()
					else
						CONS_Printf(ply, "Please use the non-admin command.")
					end
				end)
				.case("hudpreset", function()
					if not(isAdmin) then
						if tonumber(args[3]) ~= nil then
							if tonumber(args[3]) >= 1 and tonumber(args[3]) <= 10 then
								if not(silent) then CONS_Printf(ply, "\bPreset #\x82"..args[3].."\x80 has been selected!") end
								ply.hellfireHealth.options.presetNum = tonumber(args[3])
								hf.loadHUDPreset(ply)
							else
								CONS_Printf(ply, '\x85"'..args[3]..'"'.." is out of range!")
							end
						else
							CONS_Printf(ply, '\x85"'..args[3]..'"'.." is NOT a number!")
						end
					else
						CONS_Printf(ply, "Please use the non-admin command.")
					end
				end)
				.case("specialstages", function()
					if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
						CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
						CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
						return
					end

					local texts = {
						{
							trueStatement="\x82\benabled\x80 the health system on special stages",
							falseStatement="\x82\bdisabled\x80 the health system on special stages"
						},
						"special stage status to \x82%s\x80.",
						{
							trueStatement="The \x85Hellfire Saga\x80 health system is \x82now allowed\x80 on special stages.",
							falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer allowed\x80 on special stages."
						}
					}

					setSensVar(isAdmin, ply, {"allowOnSpecialStages", args[3]:lower(), texts, args[4], args[5]}, silent, onlyChanged)
				end)
				.case("allchars", function()
					if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
						CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
						CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
						return
					end

					local texts = {
						{
							trueStatement="\x82\benabled\x80 the health system on all characters",
							falseStatement="\x82\bdisabled\x80 the health system on all characters"
						},
						"all characters status to \x82%s\x80.",
						{
							trueStatement="The \x85Hellfire Saga\x80 health system is \x82now allowed\x80 on all characters.",
							falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer allowed\x80 on all characters."
						}
					}

					setSensVar(isAdmin, ply, {"allowOnAllChars", args[3]:lower(), texts, args[4], args[5]}, silent, onlyChanged)
				end)
				.case("ringspill", function()
					if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
						CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
						CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
						return
					end

					local texts = {
						{
							trueStatement="\x82\benabled\x80 ring spill mode",
							falseStatement="\x82\bdisabled\x80 ring spill mode"
						},
						"ring spill status to \x82%s\x80.",
						{
							trueStatement="The \x85Hellfire Saga\x80 health system is \x82now\x80 in ring spill mode.",
							falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer\x80 ring spill mode."
						}
					}

					setSensVar(isAdmin, ply, {"doRingSpill", args[3]:lower(), texts, args[4], args[5]}, silent, onlyChanged)

					if args[4] ~= "" then
						for target in players.iterate() do
							if target.name:lower() == args[4]:lower() then
								target.hellfireHealth.ringDeficit = 0
							end
						end
					else
						ply.hellfireHealth.ringDeficit = 0
					end
				end)
				.case("keephp", function()
					if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
						CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
						CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
						return
					end

					local texts = {
						{
							trueStatement="\x82\benabled\x80 the ability to carry health between levels",
							falseStatement="\x82\bdisabled\x80 the ability to carry health between levels"
						},
						"ability to carry health between zones status to \x82%s\x80.",
						{
							trueStatement="Health will \x82now\x80 carry between levels.",
							falseStatement="Health will \x82no longer\x80 carry between levels."
						}
					}

					setSensVar(isAdmin, ply, {"keepHealth", args[3]:lower(), texts, args[4], args[5]}, silent, onlyChanged)
				end)
				.case("fillonly", function()
					if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
						CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
						CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
						return
					end

					local texts = {
						{
							trueStatement="\x82\benabled the restriction\x80 for ring box only healing",
							falseStatement="\x82\bremoved the restriction\x80 for ring box only healing"
						},
						"ring box only status to \x82%s\x80.",
						{
							trueStatement="You have \x82\benabled\x80 the ring box only restriction on healing.",
							falseStatement="You have \x82\bremoved\x80 the ring box only restriction on healing."
						}
					}

					setSensVar(isAdmin, ply, {"fillOnly", args[3]:lower(), texts, args[4], args[5]}, silent, onlyChanged)
				end)
				.case("disablesystem", function()
					if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
						CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
						CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
						return
					end
					
					local texts = {
						{
							trueStatement="\x82\bdisabled\x80 the health system",
							falseStatement="\x82\benabled\x80 the health system"
						},
						"health system bypass to \x82%s\x80.",
						{
							trueStatement="The \x85Hellfire Saga\x80 health system is \x82now disabled\x80.",
							falseStatement="The \x85Hellfire Saga\x80 health system is \x82now enabled\x80."
						}
					}

					setSensVar(isAdmin, ply, {"disabled", args[3]:lower(), texts, args[4], args[5]}, silent, onlyChanged)
				end)
				.case("adminlock", function()
					if not(isAdmin) then CONS_Printf(ply, "\x85You are NOT an admin!"); return end

					local texts = {
						{
							trueStatement="\x82\bdisabled\x80 the ability to change gameplay settings",
							falseStatement="\x82\benabled\x80 the ability to change gameplay settings"
						},
						"ability to change gameplay settings to \x82%s\x80.",
						nil
					}

					setSensVar(isAdmin, ply, {"adminLock", args[3]:lower(), texts, args[4], args[5]}, silent, onlyChanged)
				end)
				.case("help", function()
					if not(isAdmin) then
						CONS_Printf(ply, varList_Intro..varList_Client..varList)
					else
						CONS_Printf(ply, varList_Intro..varList)
					end
				end)
				.case("", function()
					CONS_Printf(ply, "\x85You need to put in a variable name to set it!")
				end)
				.default(function()
					CONS_Printf(ply, '\x85"'..args[2]:lower()..'"'.." is NOT a valid variable!")
				end)
				.process()
		end)
		.case("help", function()
			CONS_Printf(ply, helpTxt)

			if isAdmin then
				CONS_Printf(ply, "======================================================")
				CONS_Printf(ply, "ADDITIONAL NOTES FOR ADMINISTRATORS:")
				CONS_Printf(ply, "======================================================")
				CONS_Printf(ply, "You CAN NOT mess with a player's death jingle, skin, main ring skin, health bar visibility, their client list, or if their preferences auto-save, as that's their preference.")
				CONS_Printf(ply, "There is a fourth (optional) argument [second if command is short] for this version,\nwhich allows you to modify a specific player's values.\nIt is case sensitive.")
				CONS_Printf(ply, "There is also a fifth (optional) argument [third if command is short] for this version,\nwhich allows you to send a message to the player in the fourth argument.")
				CONS_Printf(ply, "You can also set the max health and fill amount for individual players via the \"maxHealth\" and \"fillCap\" commands.")
				CONS_Printf(ply, "You can also set the serverlist (check the add command), \nand give individual players the ability to bypass it via the \"bypass\" command.")
				CONS_Printf(ply, "The syntax/formatting for this admin command is:\nhellfire_admin <cmd> <variable> <player name> <value> <optional message> (name is case-sensitive).")
			end
		end)
		.case("disable", function()
			if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
				CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
				CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
				return
			end

			local texts = {
				{
					trueStatement="\x82\bdisabled\x80 the health system",
					falseStatement="\x82\benabled\x80 the health system"
				},
				"health system bypass to \x82%s\x80.",
				{
					trueStatement="The \x85Hellfire Saga\x80 health system is \x82now disabled\x80.",
					falseStatement="The \x85Hellfire Saga\x80 health system is \x82now enabled\x80."
				}
			}

			setSensVar(isAdmin, ply, {"disabled", "true", texts, args[2], args[3]}, silent, onlyChanged)
		end)
		.case("enable", function()
			if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
				CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
				CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
				return
			end

			local texts = {
				{
					trueStatement="\x82\bdisabled\x80 the health system",
					falseStatement="\x82\benabled\x80 the health system"
				},
				"health system bypass to \x82%s\x80.",
				{
					trueStatement="The \x85Hellfire Saga\x80 health system is \x82now disabled\x80.",
					falseStatement="The \x85Hellfire Saga\x80 health system is \x82now enabled\x80."
				}
			}

			setSensVar(isAdmin, ply, {"disabled", "false", texts, args[2], args[3]}, silent, onlyChanged)
		end)
		.case("spillmode", function()
			if ply.hellfireHealth.options.adminLock and not(silent) and not(isAdmin) then --Block any changes to this setting UNLESS an admin (including the locked player) sets it.
				CONS_Printf(ply, "\x85\bYour gameplay settings are currently locked.")
				CONS_Printf(ply, "\x85\bAsk an admin to unlock it if you want to change any settings.")
				return
			end

			local newVal = tostring(not(ply.hellfireHealth.options.doRingSpill))
			if args[2]:lower() ~= "" then
				for target in players.iterate() do
					if target.name:lower() == args[2]:lower() then
						newVal = tostring(not(target.hellfireHealth.options.doRingSpill))
					end
				end
			end

			local texts = {
				{
					trueStatement="\x82\benabled\x80 ring spill mode",
					falseStatement="\x82\bdisabled\x80 ring spill mode"
				},
				"ring spill status to \x82%s\x80.",
				{
					trueStatement="The \x85Hellfire Saga\x80 health system is \x82now\x80 in ring spill mode.",
					falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer\x80 ring spill mode."
				}
			}

			setSensVar(isAdmin, ply, {"doRingSpill", newVal, texts, args[2], args[3]}, silent, onlyChanged)

			if args[2]:lower() ~= "" then
				for target in players.iterate() do
					if target.name:lower() == args[2]:lower() then
						target.hellfireHealth.ringDeficit = 0
					end
				end
			else
				ply.hellfireHealth.ringDeficit = 0
			end
		end)
		.case("maxhealth", function()
			if not(isAdmin) then CONS_Printf(ply, "\x85You are NOT an admin!"); return end

			if args[2] ~= "" then
				if args[3] ~= "" then
					if tonumber(args[2]) ~= nil then
						if tonumber(args[2]) > 0 and tonumber(args[2]) <= 50 then
							local selfTarget = ply.name:lower() == args[3]:lower()

							for target in players.iterate() do
								if target.name:lower() == args[3]:lower() then
									if tonumber(args[2]) == target.hellfireHealth.maxHealth and onlyChanged then return end

									target.hellfireHealth.maxHealth = tonumber(args[2])

									target.hellfireHealth.health = target.hellfireHealth.maxHealth

									hf.resetRings(target.hellfireHealth)
									if selfTarget then
										CONS_Printf(target, "\x86You\x80 changed your max health to \x82"..args[2].."\x80.")
									else
										CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has changed your max health to \x82"..args[2].."\x80.")
										CONS_Printf(target, "Your health has been refilled and changed to reflect this new setting.")
									end

									if args[4] ~= "" and not(selfTarget) then
										CONS_Printf(target, "\x85They also left you a message:\x82\n"..args[4])
									end

									if not(selfTarget) then
										CONS_Printf(ply, "You set \x85"..args[3].."\x80\b's max health to \x82"..args[2].."\x80.")
									end

									return
								end
							end
						else
							CONS_Printf(ply, "\x85\bThe value \""..args[2].."\" is out of range!")
						end
					else
						CONS_Printf(ply, "\x85\bThe value \""..args[2].."\" is NOT a number!")
					end
				else
					CONS_Printf(ply, "\x85\bYou need a value!")
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to change EVERYONE's max health, use the cvar instead.")
			end
		end)
		.case("fillcap", function()
			if not(isAdmin) then CONS_Printf(ply, "\x85You are NOT an admin!"); return end

			if args[2] ~= "" then
				if args[3] ~= "" then
					if tonumber(args[2]) ~= nil then
						if tonumber(args[2]) > 0 and tonumber(args[2]) < 256 then
							local selfTarget = ply.name:lower() == args[3]:lower()

							for target in players.iterate() do
								if target.name:lower() == args[3]:lower() then
									if tonumber(args[2]) == target.hellfireHealth.fillCap and onlyChanged then return end

									target.hellfireHealth.fillCap = tonumber(args[2])

									target.hellfireHealth.health = target.hellfireHealth.maxHealth

									hf.resetRings(target.hellfireHealth)
									if selfTarget then
										CONS_Printf(target, "\x86You\x80 changed your amount needed to fill a health ring to \x82"..args[2].."\x80.")
									else
										CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has changed your amount needed to fill a health ring to \x82"..args[2].."\x80.")
										CONS_Printf(target, "Your health has been refilled and changed to reflect this new setting.")
									end

									if args[4] ~= "" and not(selfTarget) then
										CONS_Printf(target, "\x85They also left you a message:\x82\n"..args[4])
									end

									if not(selfTarget) then
										CONS_Printf(ply, "You set \x85"..args[3].."\x80\b's health ring fill cap to \x82"..args[2].."\x80.")
									end

									return
								end
							end
						else
							CONS_Printf(ply, "\x85\bThe value \""..args[2].."\" is out of range!")
						end
					else
						CONS_Printf(ply, "\x85\bThe value \""..args[2].."\" is NOT a number!")
					end
				else
					CONS_Printf(ply, "\x85\bYou need a value!")
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to change EVERYONE's fill cap, use the cvar instead.")
			end
		end)
		.case("bypass", function()
			if not(isAdmin) then CONS_Printf(ply, "\x85You are NOT an admin!"); return end

			if args[2] ~= "" then
				if args[3] ~= "" then
					for target in players.iterate() do
						local selfTarget = ply.name:lower() == args[3]:lower()

						if target.name:lower() == args[3]:lower() then
							local trueTbl = {"true", "1", "on"}
							local falseTbl = {"false", "0", "off"}
							local finalVal = nil
							for _,val in pairs(trueTbl) do
								if args[2]:lower() == val then
									finalVal = true
								end
							end
							for _,val in pairs(falseTbl) do
								if args[2]:lower() == val then
									finalVal = false
								end
							end

							if finalVal ~= nil and finalVal == target.hellfireHealth.bypassServerList and onlyChanged then return end

							if finalVal == nil then
								CONS_Printf(ply, "\x85\bThe value \""..args[2].."\" is NOT \"\x82\bfalse\x85\", \"\x82\btrue\x85\", \"\x82\b0\x85\", \"\x82\b1\x85\", \"\x82\bon\x85\", or \"\x82\boff\x85\"!")
								return
							elseif finalVal == true then
								target.hellfireHealth.bypassServerList = true
								if selfTarget then
									CONS_Printf(target, "\x86You\x80 \x82\ballowed\x80 yourself to bypass the server list.")
								else
									CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\ballowed\x80 you to bypass the server list.")
									CONS_Printf(ply, "You let \x85"..args[3].."\x80\b to \x82\bbypass\x80 the server list.")
								end
							elseif finalVal == false then
								target.hellfireHealth.bypassServerList = false

								if selfTarget then
									CONS_Printf(target, "\x86You\x80 \x82\brevoked\x80 your ability to bypass the server list.")
								else
									CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\brevoked\x80 your ability to bypass the server list.")
									CONS_Printf(ply, "You took away \x85"..args[3].."\x80\b's ability to \x82\bbypass\x80 the server list.")
								end
							end

							if args[4] ~= "" and not(selfTarget) then
								CONS_Printf(target, "\x85They also left you a message:\x82\n"..args[4])
							end

							return
						end
					end
				else
					local selfTarget = ply.name:lower() == args[3]:lower()

					for target in players.iterate() do
						if target.name:lower() == args[2]:lower() then
							target.hellfireHealth.bypassServerList = not(target.hellfireHealth.bypassServerList)
							ply.hellfireHealth.lastSkin = ""

							if target.hellfireHealth.bypassServerList then
								if selfTarget then
									CONS_Printf(target, "\x86You\x80 \x82\ballowed\x80 yourself to bypass the server list.")
								else
									CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\ballowed\x80 you to bypass the server list.")
									CONS_Printf(ply, "You let \x85"..args[2].."\x80\b to \x82\bbypass\x80 the server list.")
								end
							elseif target.hellfireHealth.bypassServerList == false then
								if selfTarget then
									CONS_Printf(target, "\x86You\x80 \x82\brevoked\x80 your ability to bypass the server list.")
								else
									CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\brevoked\x80 your ability to bypass the server list.")
									CONS_Printf(ply, "You took away \x85"..args[2].."\x80\b's ability to \x82\bbypass\x80 the server list.")
								end
							end

							return
						end
					end
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to turn off the server list, use the cvar instead.")
			end
		end)
		.case("get", function()
			hf.switch(args[2]:lower())
				.case("clientlist", function()
					local list = hf.getClientList()
					local printStr = ""
					local trueClr = "\x83"
					local falseClr = "\x85"

					for skin,vals in pairs(list) do
						local skinStr = "\x82"+skin+"\x80: "
						local bannedStr = "is a banned skin? "+(vals.isBanned and trueClr or falseClr)+tostring(vals.isBanned)+"\x80, "
						local sldhckStr = "uses a shield hack? "+(vals.shieldHack and trueClr or falseClr)+tostring(vals.shieldHack)+"\x80, "
						local dthovrStr = "overrides normal death? "+(vals.deathOverride and trueClr or falseClr)+tostring(vals.deathOverride)+"\x80, "
						local dthjngStr = "ignores death jingle? "+(vals.noDeathJingle and trueClr or falseClr)+tostring(vals.noDeathJingle)+"\x80, "
						local nolossStr = "doesn't play the health loss sound? "+(vals.silentLoss and trueClr or falseClr)+tostring(vals.silentLoss)

						printStr = $+skinStr+bannedStr+sldhckStr+dthovrStr+dthjngStr+nolossStr+"\n"
					end

					CONS_Printf(ply, "Here's the entries found within the client list:\n"+printStr:sub(0, #printStr-1))
				end)
				.case("serverlist", function()
					local printStr = ""
					local trueClr = "\x83"
					local falseClr = "\x85"
					local empty = true
					
					for skin,vals in pairs(hf.srvList) do
						empty = false
						local skinStr = skin+": "
						local bannedStr = "is server banned? "+(vals.serverBanned and trueClr or falseClr)+tostring(vals.serverBanned)
						
						printStr = $+skinStr+bannedStr+"\n"
					end
					
					if empty then
						CONS_Printf(ply, "The server list is currently empty.")
					else
						CONS_Printf(ply, "Here's the entries found within the server list:\n"+printStr:sub(0, #printStr-1))
					end
				end)
				.case("list", function()
					CONS_Printf(ply, "Here are the values you can get:\n\"\x82\aclientlist\x80\" (the list of skins that are just for you :))\n\"\x82serverlist\x80\" (the lists of skins for everyone)")
				end)
				.case("", function()
					CONS_Printf(ply, "\x85You need to put in an item to get it!\x80 \nIf you want a list of items you can get, type \"\x82hellfire get list\x80\" for the possible items.")
				end)
				.default(function()
					CONS_Printf(ply, '\x85"'..args[2]..'"'.." is NOT a valid item!")
				end)
				.process()
		end)
		.case("add", function()
			if args[3] ~= "" then
				hf.switch(args[2]:lower())
					.case("bannedskins", function()
						changeList(isAdmin, ply, args[3]:lower(), false, "isBanned", "banned")
					end)
					.case("specialdeath", function()
						changeList(isAdmin, ply, args[3]:lower(), false, "deathOverride", "special death")
					end)
					.case("shieldhack", function()
						changeList(isAdmin, ply, args[3]:lower(), false, "shieldHack", "shield hack")
					end)
					.case("nojingle", function()
						changeList(isAdmin, ply, args[3]:lower(), false, "noDeathJingle", "no death jingle")
					end)
					.case("silentloss", function()
						changeList(isAdmin, ply, args[3]:lower(), false, "silentLoss", "silent loss")
					end)
					.case("serverban", function() --Server list
						if isAdmin then
							local hasChanged = hf.modifyServerList(args[3]:lower(), {serverBanned=true})

							if hasChanged then
								print("\x85\bTHE SKIN\x80 \"\x82"..args[3]:lower().."\x80\" \x85\bHAS BEEN SERVER BANNED FROM USING HELLFIRE HEALTH.\x80")
								print("\x85\bTHIS CHANGE WILL TAKE EFFECT IMMEDIATELY.\x80")
								for target in players.iterate() do
									target.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
								end
							else
								CONS_Printf(ply, "Skin \"\x82"..args[3]:lower().."\x80\" was already in the server banned list.")
							end
						else
							CONS_Printf(ply, "Please use the admin command to set this.")
						end
					end)
					.case("list", function()
						CONS_Printf(ply, "Here are the lists you can add a character to:")
						CONS_Printf(ply, listTxt)
					end)
					.case("", function()
						CONS_Printf(ply, "\x85You need to put in a variable name to add anything to it!")
					end)
					.default(function()
						CONS_Printf(ply, '\x85"'..args[2]..'"'.." is NOT a valid variable!")
					end)
					.process()
			else
				CONS_Printf(ply, "\x85You can't add nothing.")
			end
		end)
		.case("remove", function()
			if args[3] ~= "" then
				hf.switch(args[2]:lower())
					.case("bannedskins", function()
						changeList(isAdmin, ply, args[3]:lower(), true, "isBanned", "banned")
					end)
					.case("specialdeath", function()
						changeList(isAdmin, ply, args[3]:lower(), true, "deathOverride", "special death")
					end)
					.case("shieldhack", function()
						changeList(isAdmin, ply, args[3]:lower(), true, "shieldHack", "shield hack")
					end)
					.case("nojingle", function()
						changeList(isAdmin, ply, args[3]:lower(), true, "noDeathJingle", "no death jingle")
					end)
					.case("silentloss", function()
						changeList(isAdmin, ply, args[3]:lower(), true, "silentLoss", "silent loss")
					end)
					.case("serverban", function() --Server list
						if isAdmin then
							local hasChanged = hf.modifyServerList(args[3]:lower(), {serverBanned=false})

							if hasChanged then
								print("\x85\bTHE SKIN\x80 \"\x82"..args[3]:lower().."\x80\" \x85\bIS NO LONGER SERVER BANNED FROM USING HELLFIRE HEALTH.\x80")
								print("\x85\bTHIS CHANGE WILL TAKE EFFECT IMMEDIATELY.\x80")
								for target in players.iterate() do
									target.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
								end
							else
								CONS_Printf(ply, "Skin \"\x82"..args[3]:lower().."\x80\" wasn't in the server banned list.")
							end
						else
							CONS_Printf(ply, "Please use the admin command to set this.")
						end
					end)
					.case("list", function()
						CONS_Printf(ply, "Here are the lists you can remove a character from:")
						CONS_Printf(ply, listTxt)
					end)
					.case("", function()
						CONS_Printf(ply, "\x85You need to put in a variable name to add anything to it!")
					end)
					.default(function()
						CONS_Printf(ply, '\x85"'..args[2]..'"'.." is NOT a valid variable!")
					end)
					.process()
			else
				CONS_Printf(ply, "\x85You can't remove nothing.")
			end
		end)
		.case("save", function()
			if not(isAdmin) then
				CONS_Printf(ply, "\x85Saving your settings!")
				hf.savePrefs(ply)
			else
				CONS_Printf(ply, "Please use the non-admin command.")
			end
		end)
		.case("reload", function()
			if not(isAdmin) then
				CONS_Printf(ply, "\x85Reloading your settings!")
				hf.loadPrefs(ply)
			else
				CONS_Printf(ply, "Please use the non-admin command.")
			end
		end)
		.case("", function()
			if isAdmin then
				CONS_Printf(ply, "\x85You need to put in something to do anything!\x80 \nIf you don't know how to use this command, type in \"\x82hellfire_admin help\x80\" to get info.")
			else
				CONS_Printf(ply, "\x85You need to put in something to do anything!\x80 \nIf you don't know how to use this command, type in \"\x82hellfire help\x80\" to get info.")
			end
		end)
		.default(function()
			CONS_Printf(ply, '\x85"'..args[1]:lower()..'"'.." is NOT a valid argument!")
		end)
		.process()
end

--Special command for client options through the menu.
COM_AddCommand("hf_set", function(ply, jingle, skin, ring, bars, autosave, disabled, special, allchars, ringspill, keephp, fillonly)
	if jingle == nil then
		CONS_Printf(ply, "\x85This command wasn't designed for use by players... \x80please use \"\x82hellfire\x80\" instead!")
		return
	end

	local targets = {
		["deathjingle"] = jingle or "",
		["skin"] = skin or "",
		["meltring"] = ring or "",
		["healthbars"] = bars or "",
		["autosave"] = autosave or "",
		["disablesystem"] = disabled or "",
		["specialstages"] = special or "",
		["allchars"] = allchars or "",
		["ringspill"] = ringspill or "",
		["keephp"] = keephp or "",
		["fillonly"] = fillonly or "",
	}
	
	for key,val in pairs(targets) do
		if val ~= "" then
			local args = {"-s", "set", key, tostring(val)}
			hfCMD(false, ply, args)
		end
	end
end)
--Special command for admin settings on ONE person through the menu.
COM_AddCommand("hf_adminset", function(ply, targetName, disabled, special, allchars, ringspill, keephp, fillonly, adminlock, maxhealth, fillcap, bypass)
	if targetName == nil or type(targetName) ~= "string" then
		CONS_Printf(ply, "\x85This command wasn't designed for use by players... \x80please use \"\x82hellfire_admin\x80\" instead!")
		return
	end

	local targets = {
		["disablesystem"] = disabled or "",
		["specialstages"] = special or "",
		["allchars"] = allchars or "",
		["ringspill"] = ringspill or "",
		["keephp"] = keephp or "",
		["fillonly"] = fillonly or "",
		["adminlock"] = adminlock or "",
		["maxhealth"] = maxhealth or "",
		["fillcap"] = fillcap or "",
		["bypass"] = bypass or ""
	}
	for key,val in pairs(targets) do
		if val ~= "" then
			local args = {"-oc", "set", key, tostring(val), targetName}

			hf.switch(key)
				.case("maxhealth", "specialCMD")
				.case("fillcap", "specialCMD")
				.case("bypass", "specialCMD")
				.case("specialCMD", function()
					args[2] = key
					args[3] = tostring(val)
					args[4] = targetName
					args[5] = nil
				end)
				.process()

			hfCMD(true, ply, args)
		end
	end
end, COM_ADMIN)
--Special command for admin settings on ONE person through the menu.
COM_AddCommand("hf_adminsetall", function(ply, disabled, special, allchars, ringspill, keephp, fillonly, adminlock)
	if disabled == nil then
		CONS_Printf(ply, "\x85This command wasn't designed for use by players... \x80please use \"\x82hellfire_admin\x80\" instead!")
		return
	end

	local targets = {
		["disablesystem"] = disabled or "",
		["specialstages"] = special or "",
		["allchars"] = allchars or "",
		["ringspill"] = ringspill or "",
		["keephp"] = keephp or "",
		["fillonly"] = fillonly or "",
		["adminlock"] = adminlock or "",
	}
	for key,val in pairs(targets) do
		if val ~= "" and val ~= "nil" then
			local args = {"-oc", "set", key, tostring(val)}

			hfCMD(true, ply, args)
		end
	end
end, COM_ADMIN)

--Special command to add skins (with blank entries) to the server list.
COM_AddCommand("hf_serverList-new", function(ply, skin)
	if skin == nil then
		CONS_Printf(ply, "\x85This command wasn't designed for use by players... \x80please use \"\x82hellfire_admin\x80\" instead!")
		return
	end

	if hf.modifyServerList(skin:lower()) == false then
		CONS_Printf(ply, "Skin \"\x82"..skin:lower().."\x80\" was already in the server list.")
	end
end, COM_ADMIN)
--Special command to change entries to the server list.
COM_AddCommand("hf_serverList-change", function(ply, skin, serverBanned)
	if skin == nil then
		CONS_Printf(ply, "\x85This command wasn't designed for use by players... \x80please use \"\x82hellfire_admin\x80\" instead!")
		return
	end

	local targets = {
		["serverban"] = serverBanned or false,
	}
	for key,val in pairs(targets) do
		if val == "true" then
			local args = {"-oc", "add", tostring(key), skin}

			hfCMD(true, ply, args)
		elseif val == "false" then
			local args = {"-oc", "remove", tostring(key), skin}

			hfCMD(true, ply, args)
		end
	end
end, COM_ADMIN)
--Special command to remove skins from the server list.
COM_AddCommand("hf_serverList-clear", function(ply, skin)
	if skin == nil then
		CONS_Printf(ply, "\x85This command wasn't designed for use by players... \x80please use \"\x82hellfire_admin\x80\" instead!")
		return
	end

	if hf["srvList"][skin] ~= nil then
		print("\x85\bALL SERVER SETTINGS ON THE SKIN\x80 \"\x82"..skin:lower().."\x80\" \x85\bHAS BEEN REMOVED.\x80")
		print("\x85\bTHIS CHANGE WILL TAKE EFFECT IMMEDIATELY.\x80")
		for target in players.iterate() do
			target.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
		end

		hf["srvList"][skin] = nil
	else
		CONS_Printf(ply, "Skin \"\x82"..skin:lower().."\x80\" wasn't in the server list.")
	end
end, COM_ADMIN)

--pain
COM_AddCommand("hf_closehudposGUI", function(ply)
	ply.hellfireHealth.hudposGUI.visible = false
	ply.hellfireHealth.hudposGUI.previewRingCount = 5
	ply.hellfireHealth.options.presetNum = ply.hellfireHealth.hudposGUI.ogPresetNum
	hf.loadHUDPreset(ply)
end)

--Add console stuff to allow settings.
COM_AddCommand("hellfire", function(ply, arg1, arg2, arg3, arg4, arg5, arg6)
	local args = {arg1, arg2, arg3, arg4, arg5, arg6}
	hfCMD(false, ply, args)
end)

--Admin mode to modify EVERYONE (or a specific person) on the server.
COM_AddCommand("hellfire_admin", function(admin, arg1, arg2, arg3, arg4, arg5, arg6)
	local args = {arg1, arg2, arg3, arg4, arg5, arg6}
	hfCMD(true, admin, args)
end, COM_ADMIN)

--Special cvars that allows the maxHealth and fillAmt of EVERY player to be changed.
CV_RegisterVar({"hellfire_maxHealth", "5", CV_NETVAR|CV_NOINIT|CV_CALL, {MIN=1, MAX=50}, function(var)
	if var.changed or var.flags & CV_MODIFIED then
		local varString = var.string
		if var.string == "MIN" or var.value == 1 then
			varString = "THE MINIMUM AMOUNT (1) OF"
		elseif var.string == "MAX" or var.value == 50 then
			varString = "THE MAXIMUM AMOUNT (50) OF"
		end

		print("\x85\bEVERYONE'S \x87\bMAX HEALTH\x85 HAS BEEN CHANGED TO \x82"..varString.." HEALTH RINGS.\x80")
		print("\x85\bHEALTH HAS BEEN REFILLED AND CHANGED TO REFLECT THIS NEW SETTING.\x80")

		for ply in players.iterate() do
			if ply.hellfireHealth ~= nil then
				ply.hellfireHealth.maxHealth = var.value

				ply.hellfireHealth.health = ply.hellfireHealth.maxHealth

				hf.resetRings(ply.hellfireHealth)
			end
		end
	end
end})
CV_RegisterVar({"hellfire_fillCap", "5", CV_NETVAR|CV_NOINIT|CV_CALL, {MIN=1, MAX=255}, function(var)
	if var.changed or var.flags & CV_MODIFIED then
		local varString = var.string
		if var.string == "MIN" or var.value == 1 then
			varString = "THE MINIMUM AMOUNT (1) OF"
		elseif var.string == "MAX" or var.value == 255 then
			varString = "THE MAXIMUM AMOUNT (255) OF"
		end

		print("\x85\bEVERYONE'S \x87\bAMOUNT NEEDED TO FILL A HEALTH RING\x85 HAS BEEN CHANGED TO \x82"..varString.." RINGS.\x80")
		print("\x85\bHEALTH HAS BEEN REFILLED AND CHANGED TO REFLECT THIS NEW SETTING.\x80")
		
		for ply in players.iterate() do
			if ply.hellfireHealth ~= nil then
				ply.hellfireHealth.fillCap = var.value

				ply.hellfireHealth.health = ply.hellfireHealth.maxHealth

				hf.resetRings(ply.hellfireHealth)
			end
		end
	end
end})
CV_RegisterVar({"hellfire_botEnable", "Off", CV_NETVAR|CV_NOINIT|CV_CALL, {Off=0, On=1}, function(var)
	if var.value == 0 then
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bBots are no longer affected by the health system!\x80")
		end
	else
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bBots are now affected by the health system!\x80")
		end
	end
end})
CV_RegisterVar({"hellfire_allowBars", "On", CV_NETVAR|CV_NOINIT|CV_CALL, {Off=0, On=1}, function(var)
	if not(netgame) then print("\x85\bHealth bars only work in netgames!\x80") return end

	if var.value == 0 then
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bHealth bars have been disabled and removed!\x80")
			hf.removeAllBars()
		end
	else
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bHealth bars have been enabled and readded!\x80")
			for ply in players.iterate() do
				if hf.objectExists(ply) and hf.objectExists(ply.mo) then
					if hf.getPlayerBar(ply) == nil then
						local bar = P_SpawnMobjFromMobj(ply.mo, 0, 0, P_GetPlayerHeight(ply), MT_HFBAR)
						bar.target = ply.mo
						bar.clones = {}
						
						for i=0,49 do
							local clone = P_SpawnMobjFromMobj(bar, 25*FU, 25*FU, 0, MT_HFBAR)
			
							table.insert(bar.clones, clone)
						end
			
						table.insert(hf.bars, bar)
					end
				end
			end
		end
	end
end})
CV_RegisterVar({"hellfire_useSrvList", "On", CV_NETVAR|CV_NOINIT|CV_CALL, {Off=0, On=1}, function(var)
	if var.value == 0 then
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bThe server list is no longer in effect!\x80")
			print("\x85\bThis change will take effect immediately!\x80")
			for target in players.iterate() do
				target.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
			end
		end
	else
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bThe server list is now taking effect!\x80")
			print("\x85\bThis change will take effect immediately!\x80")
			for target in players.iterate() do
				target.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
			end
		end
	end
end})

--Gamemode compatibility convars.
CV_RegisterVar({"hellfire_2011x", "On", CV_NETVAR|CV_NOINIT|CV_CALL, {Off=0, On=1}, function(var)
	if var.value == 0 then
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\b2011x compatibility has been disabled!\x80")
		end
	else
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\b2011x compatibility has been enabled!\x80")
		end
	end
end})
CV_RegisterVar({"hellfire_orangedemon", "On", CV_NETVAR|CV_NOINIT|CV_CALL, {Off=0, On=1}, function(var)
	if var.value == 0 then
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bOrange Demon compatibility has been disabled!\x80")
		end
	else
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bOrange Demon compatibility has been enabled!\x80")
		end
	end
end})