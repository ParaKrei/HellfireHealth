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
]]..'"\x82\bdisable\x80"'..[[ = Shortcut to ]]..'"\x82set disablesystem true\x80"'..[[.
------------------------------------------------------
]]..'"\x82\benable\x80"'..[[ = Shortcut to ]]..'"\x82set disablesystem false\x80"'..[[.
------------------------------------------------------
]]..'"\x82\bspillmode\x80"'..[[ = Shortcut toggle for ]]..'"\x82set ringspill\x80"'..[[.
------------------------------------------------------
]]..'"\x82\bhelp\x80"'..[[ = Prints out this message.
]]

local function hfCMD(isAdmin, ply, arg1, arg2, arg3, arg4, message)
	if arg1 ~= nil then
		if arg1:lower() == "set" then
			if arg2 ~= nil then
				if arg3 ~= nil then
					if arg2:lower() == "deathjingle" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							set_hellfireBoolVar(ply, "doDeathJingle", arg3:lower(), {
								trueStatement="The \x85Hellfire Saga\x80 the death jingle is now \x82\benabled\x80.",
								falseStatement="The \x85Hellfire Saga\x80 the death jingle is now \x82\bdisabled\x80."
							})
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "skin" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							set_hellfireStrVar(ply, "skin", arg3:lower(), {returnVal="red", values={"red", "r"}}, {returnVal="yellow", values={"yellow", "y"}}, {
								statement1="The \x85Hellfire Saga\x80 now uses the color \x82\bred\x80.",
								statement2="The \x85Hellfire Saga\x80 now uses the color \x82\byellow\x80."
							})
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "healthbars" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							set_hellfireBoolVar(ply, "seeHealth", arg3:lower(), {
								trueStatement="Health bar visibility \x85(for you)\x80 is now \x82\benabled\x80.",
								falseStatement="Health bar visibility \x85(for you)\x80 is now \x82\bdisabled\x80."
							})
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "specialstages" then
						if isAdmin then
							for target in players.iterate() do
								if arg4 ~= nil then
									if target.name == arg4 then
										set_hellfireBoolVar(target, "allowOnSpecialStages", arg3:lower(), {
											trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system on special stages for you and only you.",
											falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system on special stages for you and only you."
										})

										if message ~= nil then
											CONS_Printf(target, "\x85They also left you a message:\x82\n"..message)
										end

										CONS_Printf(ply, "You set \x85"..arg4.."\x80\b's special stage status to \x82"..tostring(target.hellfireHealth.options.allowOnSpecialStages).."\x80.")

										return
									end
								else
									set_hellfireBoolVar(target, "allowOnSpecialStages", arg3:lower(), {
										trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system on special stages.",
										falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system on special stages."
									})
								end
							end

							CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's special stage status to \x82"..tostring(ply.hellfireHealth.options.allowOnSpecialStages).."\x80.")
						else
							set_hellfireBoolVar(ply, "allowOnSpecialStages", arg3:lower(), {
								trueStatement="The \x85Hellfire Saga\x80 health system is \x82now allowed\x80 on special stages.",
								falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer allowed\x80 on special stages."
							})
						end
					elseif arg2:lower() == "allchars" then
						if isAdmin then
							for target in players.iterate() do
								if arg4 ~= nil then
									if target.name == arg4 then
										set_hellfireBoolVar(target, "allowOnAllChars", arg3:lower(), {
											trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system on all characters for you and only you.",
											falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system on all characters for you and only you."
										})

										if message ~= nil then
											CONS_Printf(target, "\x85They also left you a message:\x82\n"..message)
										end

										CONS_Printf(ply, "You set \x85"..arg4.."\x80\b's all characters status to \x82"..tostring(target.hellfireHealth.options.allowOnAllChars).."\x80.")

										return
									end
								else
									set_hellfireBoolVar(target, "allowOnAllChars", arg3:lower(), {
										trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system on all characters.",
										falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system on all characters."
									})
								end
							end

							CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's all characters status to \x82"..tostring(ply.hellfireHealth.options.allowOnAllChars).."\x80.")
						else
							set_hellfireBoolVar(ply, "allowOnAllChars", arg3:lower(), {
								trueStatement="The \x85Hellfire Saga\x80 health system is \x82now allowed\x80 on all characters.",
								falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer allowed\x80 on all characters."
							})
						end
					elseif arg2:lower() == "ringspill" then
						if isAdmin then
							for target in players.iterate() do
								if arg4 ~= nil then
									if target.name == arg4 then
										set_hellfireBoolVar(target, "doRingSpill", arg3:lower(), {
											trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 ring spill mode for you and only you.",
											falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 ring spill mode for you and only you."
										})
										ply.hellfireHealth.ringDeficit = 0

										CONS_Printf(ply, "You set \x85"..arg4.."\x80\b's ring spill status to \x82"..tostring(target.hellfireHealth.options.doRingSpill).."\x80.")

										if message ~= nil then
											CONS_Printf(target, "\x85They also left you a message:\x82\n"..message)
										end

										return
									end
								else
									set_hellfireBoolVar(target, "doRingSpill", arg3:lower(), {
										trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 ring spill mode.",
										falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 ring spill mode."
									})
									ply.hellfireHealth.ringDeficit = 0
								end
							end

							CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's ring spill status to \x82"..tostring(ply.hellfireHealth.options.doRingSpill).."\x80.")
						else
							set_hellfireBoolVar(ply, "doRingSpill", arg3:lower(), {
								trueStatement="The \x85Hellfire Saga\x80 health system is \x82now\x80 in ring spill mode.",
								falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer\x80 ring spill mode."
							})
							ply.hellfireHealth.ringDeficit = 0
						end
					elseif arg2:lower() == "disablesystem" then
						if isAdmin then
							for target in players.iterate() do
								if arg4 ~= nil then
									if target.name == arg4 then
										set_hellfireBoolVar(target, "disabled", arg3:lower(), {
											trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system for you and only you.",
											falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system for you and only you."
										})

										if message ~= nil then
											CONS_Printf(target, "\x85They also left you a message:\x82\n"..message)
										end

										CONS_Printf(ply, "You set \x85"..arg4.."\x80\b's health system status to \x82"..tostring(not(target.hellfireHealth.options.disabled)).."\x80.")

										return
									end
								else
									set_hellfireBoolVar(target, "disabled", arg3:lower(), {
										trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system.",
										falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system."
									})
								end
							end

							CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's health system status to \x82"..tostring(not(ply.hellfireHealth.options.disabled)).."\x80.")
						else
							set_hellfireBoolVar(ply, "disabled", arg3:lower(), {
								trueStatement="The \x85Hellfire Saga\x80 health system is \x82now disabled\x80.",
								falseStatement="The \x85Hellfire Saga\x80 health system is \x82now enabled\x80."
							})
						end
					else
						CONS_Printf(ply, '\x85"'..arg2:lower()..'"'.." is NOT a valid variable!")
					end
				elseif arg2:lower() == "help" then
					CONS_Printf(ply, "\x8C\bAvailable variables:\x80")
					CONS_Printf(ply, "\"\x82\bdeathjingle\x80\" = Sets if the death jingle should be enabled; [either: true or false].")

					CONS_Printf(ply, "\"\x82\bskin\x80\" = Sets the color of the rings and \"HP\" text;")
					CONS_Printf(ply, "[either: red/r or yellow/y; not case-sensitive].")
					
					CONS_Printf(ply, "\"\x82\bhealthbars\x80\" = Set if you can see the health bars above players;")
					CONS_Printf(ply, "[either: true or false].")

					CONS_Printf(ply, "\"\x82\bspecialstages\x80\" = Sets if the health system works in special stages;")
					CONS_Printf(ply, "(NiGHTs stages, multiplayer special stages, etc.) [either: true or false].")

					CONS_Printf(ply, "\"\x82\ballchars\x80\" = Sets if the health system works with all characters;")
					CONS_Printf(ply, "(allows usage on characters like Takis and Samus) [either: true or false].")

					CONS_Printf(ply, "\"\x82\bringspill\x80\" = Enables a unique system that allows ring spills,")
					CONS_Printf(ply, "but upon ring loss, you will enter a ring deficit that increases with how much health you've lost.")
					CONS_Printf(ply, "In order to gain health again, you must get the ring deficit back to zero,")
					CONS_Printf(ply, "there is a counter below the health plate that shows your current ring deficit [either: true or false].")

					CONS_Printf(ply, "\"\x82\bdisablesystem\x80\" = Sets if the system should be enabled;")
					CONS_Printf(ply, "it's name is pretty self-explanatory [either: true or false].")
				else
					CONS_Printf(ply, "\x85You need to put in a new value for the variable to set it!")
				end
			else
				CONS_Printf(ply, "\x85You need to put in a variable name to set it!")
			end
		elseif arg1:lower() == "help" then
			CONS_Printf(ply, helpTxt)

			if isAdmin then
				CONS_Printf(ply, "======================================================")
				CONS_Printf(ply, "ADDITIONAL NOTES FOR ADMINISTRATORS:")
				CONS_Printf(ply, "======================================================")
				CONS_Printf(ply, "You CAN NOT mess with a player's death jingle, skin, health bar visibility, or their client list, as that's their preference.")
				CONS_Printf(ply, "There is a fourth (optional) argument [second if command is short] for this version,\nwhich allows you to modify a specific player's values.\nIt is case sensitive.")
				CONS_Printf(ply, "There is also a fifth (optional) argument [third if command is short] for this version,\nwhich allows you to send a message to the player in the fourth argument.")
				CONS_Printf(ply, "You can also set the max health and fill amount for individual players via the \"maxHealth\" and \"fillCap\" commands.")
				CONS_Printf(ply, "You can also set the serverlist (check the add command), \nand give individual players the ability to bypass it via the \"bypass\" command.")
				CONS_Printf(ply, "The syntax/formatting for this admin command is:\nhellfire_admin <cmd> <player name> <value> <optional message> (name is case-sensitive).")
			end
		elseif arg1:lower() == "disable" then
			if isAdmin then
				for target in players.iterate() do
					if arg2 ~= nil then
						if target.name == arg2 then
							set_hellfireBoolVar(target, "disabled", "true", {
								trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system for you and only you.",
								falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system for you and only you."
							})

							if arg3 ~= nil then
								CONS_Printf(target, "\x85They also left you a message:\x82\n"..arg3)
							end

							CONS_Printf(ply, "You set \x85"..arg2.."\x80\b's health system to \x82\bdisabled\x80.")

							return
						end
					else
						set_hellfireBoolVar(target, "disabled", "true", {
							trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system.",
							falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system."
						})
					end
				end

				CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's health system to \x82\bdisabled\x80.")
			else
				set_hellfireBoolVar(ply, "disabled", "true", {
					trueStatement="The \x85Hellfire Saga\x80 health system is \x82now disabled\x80.",
					falseStatement="The \x85Hellfire Saga\x80 health system is \x82now enabled\x80."
				})
			end
		elseif arg1:lower() == "enable" then
			if isAdmin then
				for target in players.iterate() do
					if arg2 ~= nil then
						if target.name == arg2 then
							set_hellfireBoolVar(target, "disabled", "false", {
								trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system for you and only you.",
								falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system for you and only you."
							})

							if arg3 ~= nil then
								CONS_Printf(target, "\x85They also left you a message:\x82\n"..arg3)
							end

							CONS_Printf(ply, "You set \x85"..arg2.."\x80\b's health system to \x82\benabled\x80.")

							return
						end
					else
						set_hellfireBoolVar(target, "disabled", "false", {
							trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 the health system.",
							falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 the health system."
						})
					end
				end

				CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's health system to \x82\benabled\x80.")
			else
				set_hellfireBoolVar(ply, "disabled", "false", {
					trueStatement="The \x85Hellfire Saga\x80 health system is \x82now disabled\x80.",
					falseStatement="The \x85Hellfire Saga\x80 health system is \x82now enabled\x80."
				})
			end
		elseif arg1:lower() == "spillmode" then
			if isAdmin then
				for target in players.iterate() do
					if arg2 ~= nil then
						if target.name == arg2 then
							set_hellfireBoolVar(target, "doRingSpill", tostring(not(target.hellfireHealth.options.doRingSpill)), {
								trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 ring spill mode for you and only you.",
								falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 ring spill mode for you and only you."
							})
							ply.hellfireHealth.ringDeficit = 0

							if arg3 ~= nil then
								CONS_Printf(target, "\x85They also left you a message:\x82\n"..arg3)
							end

							CONS_Printf(ply, "You set \x85"..arg2.."\x80\b's ring spill mode to \x82"..tostring(target.hellfireHealth.options.doRingSpill).."\x80.")

							return
						end
					else
						set_hellfireBoolVar(target, "doRingSpill", tostring(not(target.hellfireHealth.options.doRingSpill)), {
							trueStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\benabled\x80 ring spill mode.",
							falseStatement="\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\bdisabled\x80 ring spill mode."
						})
						ply.hellfireHealth.ringDeficit = 0
					end
				end

				CONS_Printf(ply, "You set \x85\bEVERYONE\x80\b's ring spill mode to \x82"..tostring(ply.hellfireHealth.options.doRingSpill).."\x80.")
			else
				set_hellfireBoolVar(ply, "doRingSpill", tostring(not(ply.hellfireHealth.options.doRingSpill)), {
					trueStatement="The \x85Hellfire Saga\x80 health system is \x82now\x80 in ring spill mode.",
					falseStatement="The \x85Hellfire Saga\x80 health system is \x82no longer\x80 ring spill mode."
				})
				ply.hellfireHealth.ringDeficit = 0
			end
		elseif arg1:lower() == "maxhealth" and isAdmin then
			if arg2 ~= nil then
				if arg3 ~= nil then
					if tonumber(arg3) ~= nil then
						if tonumber(arg3) > 0 and tonumber(arg3) < 50 then
							for target in players.iterate() do
								if target.name == arg2 then
									target.hellfireHealth.maxHealth = tonumber(arg3)

									target.hellfireHealth.health = target.hellfireHealth.maxHealth
									target.hellfireHealth.curRing = target.hellfireHealth.maxHealth-1

									resetRings(target.hellfireHealth)
									CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has changed your max health to \x82"..arg3.."\x80.")
									CONS_Printf(target, "Your health has been refilled and changed to reflect this new setting.")

									if arg4 ~= nil then
										CONS_Printf(target, "\x85They also left you a message:\x82\n"..arg4)
									end

									CONS_Printf(ply, "You set \x85"..arg2.."\x80\b's max health to \x82"..tostring(target.hellfireHealth.maxHealth).."\x80.")

									return
								end
							end
						else
							CONS_Printf(ply, "\x85\bThe value \""..arg3.."\" is out of range!")
						end
					else
						CONS_Printf(ply, "\x85\bThe value \""..arg3.."\" is NOT a number!")
					end
				else
					CONS_Printf(ply, "\x85\bYou need a value!")
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to change EVERYONE's max health, use the cvar instead.")
			end
		elseif arg1:lower() == "fillcap" and isAdmin then
			if arg2 ~= nil then
				if arg3 ~= nil then
					if tonumber(arg3) ~= nil then
						if tonumber(arg3) > 0 and tonumber(arg3) < 256 then
							for target in players.iterate() do
								if target.name == arg2 then
									target.hellfireHealth.fillCap = tonumber(arg3)

									target.hellfireHealth.health = target.hellfireHealth.maxHealth
									target.hellfireHealth.curRing = target.hellfireHealth.maxHealth-1

									resetRings(target.hellfireHealth)
									CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has changed your amount needed to fill a health ring to \x82"..arg3.."\x80.")
									CONS_Printf(target, "Your health has been refilled and changed to reflect this new setting.")

									if arg4 ~= nil then
										CONS_Printf(target, "\x85They also left you a message:\x82\n"..arg4)
									end

									CONS_Printf(ply, "You set \x85"..arg2.."\x80\b's health ring fill cap to \x82"..tostring(target.hellfireHealth.fillCap).."\x80.")

									return
								end
							end
						else
							CONS_Printf(ply, "\x85\bThe value \""..arg3.."\" is out of range!")
						end
					else
						CONS_Printf(ply, "\x85\bThe value \""..arg3.."\" is NOT a number!")
					end
				else
					CONS_Printf(ply, "\x85\bYou need a value!")
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to change EVERYONE's fill cap, use the cvar instead.")
			end
		elseif arg1:lower() == "bypass" and isAdmin then
			if arg2 ~= nil then
				if arg3 ~= nil then
					for target in players.iterate() do
						if target.name == arg2 then
							local trueTbl = {"true", "1", "on"}
							local falseTbl = {"false", "0", "off"}

							if table.concat(trueTbl, " "):find(arg3:lower()) then
								target.hellfireHealth.bypassServerList = true
								CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\ballowed\x80 you to bypass the server list.")
								CONS_Printf(ply, "You let \x85"..arg2.."\x80\b to \x82\bbypass\x80 the server list.")
							elseif table.concat(falseTbl, " "):find(arg3:lower())
								target.hellfireHealth.bypassServerList = false
								CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\brevoked\x80 your ability to bypass the server list.")
								CONS_Printf(ply, "You took away \x85"..arg2.."\x80\b's ability to \x82\bbypass\x80 the server list.")
							else
								print("ERR: \""..tostring(arg3:lower()).."\" is nether true nor false.")
							end

							if arg4 ~= nil then
								CONS_Printf(target, "\x85They also left you a message:\x82\n"..arg3)
							end

							return
						end
					end
				else
					for target in players.iterate() do
						if target.name == arg2 then
							target.hellfireHealth.bypassServerList = not(target.hellfireHealth.bypassServerList)
							ply.hellfireHealth.lastSkin = ""

							if target.hellfireHealth.bypassServerList then
								CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\ballowed\x80 you to bypass the server list.")
								CONS_Printf(ply, "You let \x85"..arg2.."\x80\b to \x82\bbypass\x80 the server list.")
							elseif target.hellfireHealth.bypassServerList == false then
								CONS_Printf(target, "\x8B\bAdministrator \x86"..ply.name.."\x80 has \x82\brevoked\x80 your ability to bypass the server list.")
								CONS_Printf(ply, "You took away \x85"..arg2.."\x80\b's ability to \x82\bbypass\x80 the server list.")
							end

							return
						end
					end
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to turn off the server list, use the cvar instead.")
			end
		elseif arg1:lower() == "get" then
			if arg2 ~= nil then
				if arg2:lower() == "clientlist" then
					local list = getClientList()
					local printStr = ""

					for skin,vals in pairs(list) do
						local skinStr = skin+": "
						local bannedStr = "is a banned skin? "+tostring(vals.isBanned)+", "
						local sldhckStr = "uses a shield hack? "+tostring(vals.shieldHack)+", "
						local dthovrStr = "overrides normal death? "+tostring(vals.deathOverride)

						printStr = $+skinStr+bannedStr+sldhckStr+dthovrStr+"\n"
					end

					CONS_Printf(ply, "Here's the entries found within the client list:\n"+printStr:sub(0, #printStr-1))
				elseif arg2:lower() == "serverlist" then
					CONS_Printf(ply, "WIP")
				elseif arg2:lower() == "list" then
					CONS_Printf(ply, "Here are the values you can get:\n\"\x82\aclientlist\x80\" (the list of skins that are just for you :))\n\"\x82serverlist\x80\" (the lists of skins for everyone)")
				else
					CONS_Printf(ply, '\x85"'..arg2:lower()..'"'.." is NOT a valid item!")
				end
			else
				CONS_Printf(ply, "\x85You need to put in an item to get it!\x80 \nIf you want a list of items you can get, type \"\x82hellfire get list\x80\" for the possible items.")
			end
		elseif arg1:lower() == "add" then
			if arg2 ~= nil then
				if arg3 ~= nil then
					if arg2:lower() == "bannedskins" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							local hasChanged = modifyClientList(arg3:lower(), {isBanned=true})

							if hasChanged then
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" has been added to the banned list.")
								ply.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" was already in the banned list.")
							end
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "specialdeath" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							local hasChanged = modifyClientList(arg3:lower(), {deathOverride=true})

							if hasChanged then
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" has been added to the special death list.")
								ply.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" was already in the special death list.")
							end
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "shieldhack" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							local hasChanged = modifyClientList(arg3:lower(), {shieldHack=true})

							if hasChanged then
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" has been added to the shield hack list.")
								ply.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" was already in the shield hack list.")
							end
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "serverban" then --Server list
						if isAdmin then
							local hasChanged = modifyServerList(arg3:lower(), {isBanned=true})

							if hasChanged then
								print("\x85\bTHE SKIN\x80 \"\x82"..arg3:lower().."\x80\" \x85\bHAS BEEN SERVER BANNED FROM USING HELLFIRE HEALTH.\x80")
								print("\x85\bTHIS CHANGE WILL TAKE EFFECT IMMEDIATELY.\x80")
								for target in players.iterate() do
									target.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
								end
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" was already in the server banned list.")
							end
						else
							CONS_Printf(ply, "Please use the admin command to set this.")
						end
					else
						CONS_Printf(ply, '\x85"'..arg2:lower()..'"'.." is NOT a valid variable!")
					end
				elseif arg2:lower() == "list" then
					CONS_Printf(ply, "Here are the lists you can add a character to:\n\"\x82\abannedskins\x80\" (characters that aren't allowed to use the health system)")
					CONS_Printf(ply, "\"\x82specialdeath\x80\" (characters with unique deaths)")
					CONS_Printf(ply, "\"\x82shieldhack\x80\" (characters that use a shield in a hacky way, e.g. Mario Bros.)")
				else
					CONS_Printf(ply, "\x85You can't add nothing.")
				end
			else
				CONS_Printf(ply, "\x85You need to put in a variable name to add anything to it!")
			end
		elseif arg1:lower() == "remove" then
			if arg2 ~= nil then
				if arg3 ~= nil then
					if arg2:lower() == "bannedskins" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							local hasChanged = modifyClientList(arg3:lower(), {isBanned=false})

							if hasChanged then
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" has been removed from the banned list.")
								ply.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" wasn't in the banned list.")
							end
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "specialdeath" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							local hasChanged = modifyClientList(arg3:lower(), {deathOverride=false})

							if hasChanged then
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" has been removed from the special death list.")
								ply.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" wasn't in the special death list.")
							end
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "shieldhack" then
						--Client tweak ONLY; no admin tweaking allowed.
						if not(isAdmin) then
							local hasChanged = modifyClientList(arg3:lower(), {shieldHack=false})

							if hasChanged then
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" has been removed from the shield hack list.")
								ply.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" wasn't in the shield hack list.")
							end
						else
							CONS_Printf(ply, "Please use the non-admin command to set this.")
						end
					elseif arg2:lower() == "serverban" then --Server list
						if isAdmin then
							local hasChanged = modifyServerList(arg3:lower(), {isBanned=false})

							if hasChanged then
								print("\x85\bTHE SKIN\x80 \"\x82"..arg3:lower().."\x80\" \x85\bIS NO LONGER SERVER BANNED FROM USING HELLFIRE HEALTH.\x80")
								print("\x85\bTHIS CHANGE WILL TAKE EFFECT IMMEDIATELY.\x80")
								for target in players.iterate() do
									target.hellfireHealth.lastSkin = "" --Reset the lastSkin variable to force the main code to refresh.
								end
							else
								CONS_Printf(ply, "Skin \"\x82"..arg3:lower().."\x80\" wasn't in the server banned list.")
							end
						else
							CONS_Printf(ply, "Please use the admin command to set this.")
						end
					else
						CONS_Printf(ply, '\x85"'..arg2:lower()..'"'.." is NOT a valid variable!")
					end
				elseif arg2:lower() == "list" then
					CONS_Printf(ply, "Here are the lists you can remove a character from:\n\"\x82\abannedskins\x80\" (characters that aren't allowed to use the health system)\n\"\x82specialdeath\x80\" (characters with unique deaths)\n\"\x82shieldhack\x80\" (characters that use a shield in a hacky way, e.g. Mario Bros.)")
				else
					CONS_Printf(ply, "\x85You can't remove nothing.")
				end
			else
				CONS_Printf(ply, "\x85You need to put in a variable name to remove anything to it!")
			end
		else
			CONS_Printf(ply, '\x85"'..arg1:lower()..'"'.." is NOT a valid argument!")
		end
	else
		if isAdmin then
			CONS_Printf(ply, "\x85You need to put in something to do anything!\x80 \nIf you don't know how to use this command, type in \"\x82hellfire_admin help\x80\" to get info.")
		else
			CONS_Printf(ply, "\x85You need to put in something to do anything!\x80 \nIf you don't know how to use this command, type in \"\x82hellfire help\x80\" to get info.")
		end
	end
end

--Add console stuff to allow settings.
COM_AddCommand("hellfire", function(ply, arg1, arg2, arg3)
	hfCMD(false, ply, arg1, arg2, arg3)
end)

--Admin mode to modify EVERYONE (or a specific person) on the server.
COM_AddCommand("hellfire_admin", function(admin, arg1, arg2, arg3, target, message)
	hfCMD(true, admin, arg1, arg2, arg3, target, message)
end, COM_ADMIN)

--Special cvars that allows the maxHealth and fillAmt of EVERY player to be changed.
CV_RegisterVar({"hellfire_maxHealth", "5", CV_NETVAR|CV_NOINIT|CV_CALL, {MIN=1, MAX=49}, function(var)
	if var.changed or var.flags & CV_MODIFIED then
		local varString = var.string
		if var.string == "MIN" or var.value == 1 then
			varString = "THE MINIMUM AMOUNT (1) OF"
		elseif var.string == "MAX" or var.value == 49 then
			varString = "THE MAXIMUM AMOUNT (49) OF"
		end
		print("\x85\bEVERYONE'S MAX HEALTH HAS BEEN CHANGED TO "..varString.." HEALTH RINGS.\x80")
		print("\x85\bHEALTH HAS BEEN REFILLED AND CHANGED TO REFLECT THIS NEW SETTING.\x80")
		for ply in players.iterate() do
			if ply.hellfireHealth ~= nil then
				ply.hellfireHealth.maxHealth = var.value

				ply.hellfireHealth.health = ply.hellfireHealth.maxHealth
				ply.hellfireHealth.curRing = ply.hellfireHealth.maxHealth-1

				resetRings(ply.hellfireHealth)
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
		print("\x85\bEVERYONE'S AMOUNT NEEDED TO FILL A HEALTH RING HAS BEEN CHANGED TO "..varString.." RINGS.\x80")
		print("\x85\bHEALTH HAS BEEN REFILLED AND CHANGED TO REFLECT THIS NEW SETTING.\x80")
		for ply in players.iterate() do
			if ply.hellfireHealth ~= nil then
				ply.hellfireHealth.fillCap = var.value

				ply.hellfireHealth.health = ply.hellfireHealth.maxHealth
				ply.hellfireHealth.curRing = ply.hellfireHealth.maxHealth-1

				resetRings(ply.hellfireHealth)
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
			removeAllBars()
		end
	else
		if var.changed or var.flags & CV_MODIFIED then
			print("\x85\bHealth bars have been enabled and readded!\x80")
			for ply in players.iterate() do
				if objectExists(ply) and objectExists(ply.mo) then
					if getPlayerBar(ply) == nil then
						local bar = P_SpawnMobjFromMobj(ply.mo, 0, 0, P_GetPlayerHeight(ply), MT_HFBAR)
						bar.target = ply.mo
						bar.clones = {}
						
						for i=0,49 do
							local clone = P_SpawnMobjFromMobj(bar, 25*FU, 25*FU, 0, MT_HFBAR)
			
							table.insert(bar.clones, clone)
						end
			
						table.insert(HFBars, bar)
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