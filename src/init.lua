--[[
Hellfire Saga's healthbar ported to SRB2.
Created by ParaKrei.

Graphics and sounds made by ParaKrei (sounds are heavily edited versions of sounds from the Genesis/Mega Drive Sonic games),
Death jingle is by Michiru Yamane for Castlevania Bloodlines (the same one used in Hellfire Saga);
ripped by DJ Squarewave from Project 2612, HQ conversion by archivologist from Internet Archive;
URL: ("https://archive.org/details/md_music_castlevania_bloodlines/").
]]

--[[
NOTE: All of this code will be split into seperate files and some clean-up will occur once 2.2.14 comes out.
There also might be a GUI coded in to modify settings as well, since 2.2.14 will add in the ability to ignore player input with a variable.
SRC: ("https://git.do.srb2.org/STJr/SRB2/-/merge_requests/2185").
]]

--Freeslot stuff
freeslot("SPR_HFHP") --Health Plate
freeslot("SPR_HFMN") --Main Ring
freeslot("SPR_HFHR") --Half-Ring
freeslot("SPR_HFBP") --A little black pixel for drawing rectangles
freeslot("sfx_hfloss") --Health loss SFX
sfxinfo[sfx_hfloss].caption = "\x85\bHealth Ring loss\x80"
freeslot("sfx_hfgain") --Health gain SFX
sfxinfo[sfx_hfgain].caption = "\x82\bHealth Ring gain\x80"
freeslot("sfx_hffill") --Health fill SFX
sfxinfo[sfx_hffill].caption = "\x87\bHealth Ring fill\x80"

--ACTUAL SCRIPT STARTS HERE--

--Just a clamp function, can be found everywhere at this point.
--Based off of pgimeno's version on the LÖVE board.
--(https://love2d.org/forums/viewtopic.php?t=1856 on page 2)
local function clamp(val, minVal, maxVal)
	return(max(minVal, min(maxVal, val)))
end

--Ring resetter function.
local function resetRings(hellfire)
	local basePos = {x=hudinfo[HUD_RINGS].x-1, y=hudinfo[HUD_RINGS].y+15} --Get the position of the og "RINGS" HUD element and position off of that.

	hellfire.rings = {} --Clear rings table.
	hellfire.ringWrapCount = 0 --Clear wrap count.
	hellfire.ringXOffset = 0 --Reset offset.
	hellfire.ringWrapAt = 7 --Reset wrap pos.
	hellfire.ringWrapAt2 = 0 --Reset wrap2 pos.
	hellfire.endWidth = 1 --Reset end cap width.

	for i=1,hellfire.maxHealth-1 do
		local tbl = {
			fillAmt=0, state="filled", doFlash=false, doShrivel=false,
			frame=0, isAnimating=false, x=0, y=0
		}
		hellfire.rings[i] = tbl

		--Position code.
		hellfire.ringXOffset = $+8
		if i % hellfire.ringWrapAt == hellfire.ringWrapAt2 then
			if hellfire.ringWrapAt2 == 0 then
				hellfire.ringWrapAt2 = hellfire.ringWrapAt-1
			else
				hellfire.ringWrapAt2 = $-1
			end

			hellfire.ringWrapCount = $+1
			hellfire.ringXOffset = 8
			hellfire.endWidth = $+1
		end

		hellfire.rings[i].x = (basePos.x+40)+hellfire.ringXOffset
		hellfire.rings[i].y = basePos.y+((16+4)*hellfire.ringWrapCount)
	end
end

--Initalize the table.
local function initHellfire(ply)
	if ply.hellfireHealth == nil then
		ply.hellfireHealth = {
			options = {
				disabled = false,
				allowOnSpecialStages = false,
				allowOnAllChars = false,
				doRingSpill = false,
				doDeathJingle = true,
			},
			notAllowed = false,
			maxHealth = 5,
			fillCap = 5,
			health = 0,
			lastRingCount = ply.rings,
			ringDeficit = 0,
			ringDefColor = V_YELLOWMAP,
			curRing = 0,
			mainRing = {frame=0, isAnimating=false, animDone=false},
			healthPlate = {frame=0, isAnimating=false, animDone=false},
			rings = {},
			ringXOffset = 0,
			ringWrapAt = 0,
			ringWrapAt2 = 0,
			ringWrapCount = 0,
			endWidth = 1,
			isDead = false,
			diedFromHealthLoss = false,
			transStuff = {
				overallAlpha = 1,
				isFadingHUD = false,
				doFade = false,
				lastTic = 0
			}
		}
	end
	local hellfire = ply.hellfireHealth

	--Reset stuff.
	hellfire.isDead = false
	hellfire.diedFromHealthLoss = false
	hellfire.transStuff.overallAlpha = 1
	hellfire.ringDeficit = 0
	hellfire.ringDefColor = V_YELLOWMAP
	hellfire.notAllowed = false
	hellfire.mainRing = {frame=0, isAnimating=false, animDone=false}
	hellfire.healthPlate = {frame=0, isAnimating=false, animDone=false}
	hellfire.transStuff.overallAlpha = 1
	hellfire.transStuff.isFadingHUD = false

	--Fetch the cvars and set them.
	hellfire.maxHealth = CV_FindVar("hellfire_maxHealth").value
	hellfire.fillCap = CV_FindVar("hellfire_fillCap").value

	--Setup the health and curRing since it can't be done at define.
	hellfire.health = hellfire.maxHealth
	hellfire.curRing = hellfire.maxHealth-1

	--Setup the rings.
	resetRings(hellfire)
end

local function set_hellfireBoolVar(ply, var, newVal, replyTbl)
	local hellfire = ply.hellfireHealth

	local trueTbl = {"true", "1", "on"}
	local falseTbl = {"false", "0", "off"}

	if table.concat(trueTbl, " "):find(newVal) then
		hellfire.options[var] = true

		if replyTbl ~= nil then
			CONS_Printf(ply, replyTbl.trueStatement)
		end
	elseif table.concat(falseTbl, " "):find(newVal)
		hellfire.options[var] = false

		if replyTbl ~= nil then
			CONS_Printf(ply, replyTbl.falseStatement)
		end
	else
		print("ERR: \""..tostring(newVal).."\" is nether true nor false.")
	end
end

local function set_hellfireStrVar(ply, var, newVal, valTbl1, valTbl2, replyTbl)
	local hellfire = ply.hellfireHealth

	if table.concat(valTbl1.values, " "):find(newVal) then
		hellfire.options[var] = valTbl1.returnVal

		if replyTbl ~= nil then
			CONS_Printf(ply, replyTbl.statement1)
		end
	elseif table.concat(valTbl2.values, " "):find(newVal)
		hellfire.options[var] = valTbl2.returnVal

		if replyTbl ~= nil then
			CONS_Printf(ply, replyTbl.statement2)
		end
	else
		print("ERR: \""..tostring(newVal).."\" doesn't match any of the specified values.")
	end
end

local helpTxt = [[
======================================================
]]..'\x85Hellfire Saga\x80 health system command arguments:\n'..[[
======================================================
]]..'"\x82set\x80"'..[[ = Set variables for ONLY yourself.
EXAMPLE: "hellfire set disablesystem true".

]]..'\x8C\bAvailable variables:\x80\n'..[[
]]..'"\x82\bdeathjingle\x80"'..[[ = Sets if the death jingle should be enabled; [either: true or false].

]]..'"\x82\bspecialstages\x80"'..[[ = Sets if the health system works in special stages
(NiGHTs stages, multiplayer special stages, etc.) [either: true or false].

]]..'"\x82\ballchars\x80"'..[[ = Sets if the health system works with all characters
(allows usage on characters like Takis and Samus) [either: true or false].

]]..'"\x82\bringspill\x80"'..[[ = Enables a unique system that allows ring spills,
but upon ring loss, you will enter a ring deficit that increases with how much health you've lost.
In order to gain health again, you must get the ring deficit back to zero,
there is a counter below the health plate that shows your current ring deficit [either: true or false].

]]..'"\x82\bdisablesystem\x80"'..[[ = Sets if the system should be enabled;
it's name is pretty self-explanatory [either: true or false].
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
						set_hellfireBoolVar(ply, "doDeathJingle", arg3:lower(), {
							trueStatement="The \x85Hellfire Saga\x80 the death jingle is now \x82\benabled\x80.",
							falseStatement="The \x85Hellfire Saga\x80 the death jingle is now \x82\bdisabled\x80."
						})
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
				CONS_Printf(ply, "You CAN NOT mess with a player's death jingle, as that's their preference.")
				CONS_Printf(ply, "There is a fourth (optional) argument [second if command is short] for this version,\nwhich allows you to modify a specific player's values.\nIt is case sensitive.")
				CONS_Printf(ply, "There is also a fifth (optional) argument [third if command is short] for this version,\nwhich allows you to send a message to the player in the fourth argument.")
				CONS_Printf(ply, "You can also set the max health and fill amount for individual players via the \"maxHealth\" and \"fillCap\" commands.")
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
				if tonumber(arg3) ~= nil then
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
					CONS_Printf(ply, "\x85\bThe value \""..arg3.."\" is NOT a number!")
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to change EVERYONE's max health, use the cvar instead.")
			end
		elseif arg1:lower() == "fillcap" and isAdmin then
			if arg2 ~= nil then
				if tonumber(arg3) ~= nil then
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
					CONS_Printf(ply, "\x85\bThe value \""..arg3.."\" is NOT a number!")
				end
			else
				CONS_Printf(ply, "\x85\bYou need to put in a player's name to use this command!\nIf you want to change EVERYONE's fill cap, use the cvar instead.")
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
	if var.changed then
		local varString = var.string
		if var.string == "MIN" or var.value == 1 then
			varString = "THE MINIMUM AMOUNT (1) OF"
		elseif var.string == "MAX" or var.value == 49 then
			varString = "THE MAXIMUM AMOUNT (49) OF"
		end
		print("\x85\bEVERYONE'S MAX HEALTH HAS BEEN CHANGED TO "..varString.." HEALTH RINGS.\x80")
		print("\x85\bHEALTH HAS BEEN REFILLED AND CHANGED TO REFLECT THIS NEW SETTING.\x80")
		for ply in players.iterate() do
			ply.hellfireHealth.maxHealth = var.value

			ply.hellfireHealth.health = ply.hellfireHealth.maxHealth
			ply.hellfireHealth.curRing = ply.hellfireHealth.maxHealth-1

			resetRings(ply.hellfireHealth)
		end
	end
end})
CV_RegisterVar({"hellfire_fillCap", "5", CV_NETVAR|CV_NOINIT|CV_CALL, {MIN=1, MAX=255}, function(var)
	if var.changed then
		local varString = var.string
		if var.string == "MIN" or var.value == 1 then
			varString = "THE MINIMUM AMOUNT (1) OF"
		elseif var.string == "MAX" or var.value == 255 then
			varString = "THE MAXIMUM AMOUNT (255) OF"
		end
		print("\x85\bEVERYONE'S AMOUNT NEEDED TO FILL A HEALTH RING HAS BEEN CHANGED TO "..varString.." RINGS.\x80")
		print("\x85\bHEALTH HAS BEEN REFILLED AND CHANGED TO REFLECT THIS NEW SETTING.\x80")
		for ply in players.iterate() do
			ply.hellfireHealth.fillCap = var.value

			ply.hellfireHealth.health = ply.hellfireHealth.maxHealth
			ply.hellfireHealth.curRing = ply.hellfireHealth.maxHealth-1

			resetRings(ply.hellfireHealth)
		end
	end
end})
CV_RegisterVar({"hellfire_botEnable", "Off", CV_NETVAR|CV_NOINIT|CV_CALL, {Off=0, On=1}, function(var)
	if var.value == 0 then
		if var.changed then
			print("\x85\bBots are no longer affected by the health system!\x80")
		end
	else
		if var.changed then
			print("\x85\bBots are now affected by the health system!\x80")
		end
	end
end})

--First/last ring with state finder (returns position in table).
local function getRingWithState(hellfire, state, doFirst)
	if doFirst == nil then doFirst = false end

	if doFirst then
		for i=1,#hellfire.rings do
			if hellfire.rings[i].state == state then
				return(i)
			end
		end
	else
		for i=#hellfire.rings,1,-1 do
			if hellfire.rings[i].state == state then
				return(i)
			end
		end
	end

	return(nil)
end

--Skin comparison function for characters using shield hacks for their damage system.
local function isShieldHackSkin(ply)
	if ply.mo == nil return(true) end

	local skinList = {
		"mario", "luigi",
	}

	for _,skin in ipairs(skinList) do
		if ply.mo.skin == skin then
			return(true)
		end
	end

	return(false)
end

--Skin comparison function for characters using unique systems for death.
local function isSpecialDeathSkin(ply)
	if ply.mo == nil return(true) end

	local skinList = {
		"doomguy",
	}

	for _,skin in ipairs(skinList) do
		if ply.mo.skin == skin then
			return(true)
		end
	end

	return(false)
end

--A half-port of P_HitDeathMessages for any modes requiring it (since it never executes with HellfireHealth on).
--This is only used in DamageMobj since KillMobj still executes normally.
--This might become it's own standalone mod, since this is a issue with any mod that blocks normal damage code execution.
local function hurtMessages(target, cause, src, dmgType)
	--ONLY execute if the gametype has GTR_HURTMESSAGES.
	if gametyperules & GTR_HURTMESSAGES then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth

		--ONLY continue if HellfireHealth is on.
		if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			local targetName = ply.name
			local srcName = src.player.name

			if src.player.state == PST_DEAD then
				srcName = "The late "..src.player.name
			end

			if src.flags & MF_PUSHABLE then
				print(srcName.."'s playtime with heavy objects hit "..targetName..".")
			elseif cause ~= nil and cause.valid then
				local objType = cause.type

				if objType == MT_PLAYER then
					if dmgType == DMG_NUKE then
						print(srcName.."'s armageddon blast hit "..targetName..".")
					elseif ((cause.player.powers[pw_shield] & SH_NOSTACK) == SH_ELEMENTAL) and (cause.player.pflags & PF_SHIELDABILITY) then
						print(srcName.."'s elemental stomp hit "..targetName..".")
					elseif cause.player.powers[pw_invulnerability] then
						print(srcName.."'s invincibility aura hit "..targetName..".")
					elseif cause.player.powers[pw_super] then
						print(srcName.."'s super aura hit "..targetName..".")
					else
						print(srcName.."'s tagging hand hit "..targetName..".")
					end
				elseif objType == MT_SPINFIRE then
					print(srcName.."'s elemental fire trail hit "..targetName..".")
				elseif objType == MT_REDRING then
					if cause.flags2 & MF2_RAILRING then
						print(srcName.."'s rail ring hit "..targetName..".")
					else
						print(srcName.."'s thrown ring hit "..targetName..".")
					end
				elseif objType == MT_THROWNBOUNCE then
					print(srcName.."'s bounce ring hit "..targetName..".")
				elseif objType == MT_THROWNINFINITY then
					print(srcName.."'s infinity ring hit "..targetName..".")
				elseif objType == MT_THROWNAUTOMATIC then
					print(srcName.."'s automatic ring hit "..targetName..".")
				elseif objType == MT_THROWNSCATTER then
					print(srcName.."'s scatter ring hit "..targetName..".")
				elseif objType == MT_THROWNEXPLOSION then
					print(srcName.."'s explosion ring hit "..targetName..".")
				elseif objType == MT_THROWNGRENADE then
					print(srcName.."'s grenade ring hit "..targetName..".")
				else
					print(srcName.." hit "..targetName..".")
				end
			elseif src ~= nil and src.valid then
				local objType = src.type

				if objType == MT_EGGMAN_ICON then
					print(targetName.." was hit by Eggman's nefarious TV magic.")
				elseif objType == MT_SPIKE or objType == MT_WALLSPIKE then
					print(targetName.." was hit by spikes.")
				else
					print(targetName.." was hit by an environmental hazard.")
				end
			else
				if dmgType == DMG_WATER then
					print(targetName.." was hit by dangerous water.")
				elseif dmgType == DMG_FIRE then
					print(targetName.." was hit by molten lava.")
				elseif dmgType == DMG_ELECTRIC then
					print(targetName.." was hit by electricity.")
				elseif dmgType == DMG_SPIKE then
					print(targetName.." was hit by spikes.")
				else
					print(targetName.." was hit by an environmental hazard.")
				end
			end
		end
	end
end

local function killPlayer(hellfire, healthLoss, target, cause, src)
	local ply = target.player

	hellfire.isDead = true
	hellfire.curRing = 1
	hellfire.health = 0
	for i=1,#hellfire.rings do
		hellfire.rings[i].state = "empty"
		hellfire.rings[i].fillAmt = 0
		hellfire.rings[i].doFlash = false
		if hellfire.rings[i].state ~= "empty" then
			hellfire.rings[i].doShrivel = true
		end
	end
	
	if healthLoss then
		hellfire.diedFromHealthLoss = true --Done to ensure nothing occurs twice.

		P_DamageMobj(target, cause, src, 666, DMG_INSTAKILL) --Funny reference.

		--Kill the player anyways if they somehow lived the above DamageMobj.
		if ply.playerstate ~= PST_DEAD then
			P_KillMobj(target, cause, src, DMG_INSTAKILL)
		end
	end

	--Stuff for the death jingle (Can't use in splitscreen, since the music doesn't come back when P2 dies; this is a bug with SRB2).
	if hellfire.options.doDeathJingle and not(splitscreen) then
		P_PlayJingleMusic(ply, "HFDTH", MUSIC_RELOADRESET, false, JT_OTHER)
		S_StartMusicCaption("\x8F\bDeath\x80", 3*TICRATE, ply)
	end
end

--Damage handler.
local function dmgHandler(target, cause, src, dmg, dmgType)
	if not(target) or not(target.valid) then return end --Non-valid checker
	if target.player.bot and CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.

	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		--Setup the ring variables.
		local targetRing = hellfire.rings[hellfire.curRing]
		local ringAhead = hellfire.rings[hellfire.curRing+1]

		--Kill the player if they take damage with a health value of one.
		if hellfire.health == 1 then
			killPlayer(hellfire, true, target, cause, src)
		else
			--Hurt code; removed an unnecessary pain check.
			P_DoPlayerPain(ply, cause, src)
			hurtMessages(target, cause, src, dmgType)

			--Remove/damage the shield if it exists instead (also some special exceptions for characters like the Mario Bros to get around their shield hack).
			if ply.powers[pw_shield] ~= SH_NONE and not(isShieldHackSkin(ply)) then
				P_RemoveShield(ply) --Damage the shield.
				P_PlayDeathSound(target, ply) --Play the normal damage sound.
			else
				S_StartSound(target, sfx_hfloss, ply) --Play the health ring loss sfx.
				--Do the multiplayer burst stuff.
				P_PlayerEmeraldBurst(ply)
				P_PlayerWeaponPanelOrAmmoBurst(ply)
				P_PlayerFlagBurst(ply)

				--Ring code (spills and subtractions).
				if hellfire.options.doRingSpill then
					local subtractRingAmt = 2*((hellfire.maxHealth-hellfire.health)+1)
					local newRingCount = ply.rings-subtractRingAmt

					if newRingCount > 0 then
						P_PlayerRingBurst(ply, subtractRingAmt)
						ply.rings = newRingCount
					else
						newRingCount = subtractRingAmt+(ply.rings-subtractRingAmt)
						P_PlayerRingBurst(ply, newRingCount)
						ply.rings = 0
					end

					hellfire.ringDeficit = subtractRingAmt
				else
					--No ring spill? You just lose rings, then.
					if ply.rings-2*((hellfire.maxHealth-hellfire.health)+1) < 0 then --No negatives.
						ply.rings = 0
					else
						ply.rings = $-2*((hellfire.maxHealth-hellfire.health)+1)
					end
				end

				--Health stuff.
				if hellfire.health > 1 then
					hellfire.health = $-1
					targetRing.fillAmt = 0
					targetRing.state = "empty"
					targetRing.doShrivel = true --Do ring loss animation
					if ringAhead ~= nil and ringAhead.fillAmt > 0 then --Remove any progress on next ring.
						ringAhead.fillAmt = 0
					end

					--Get the next ring to fill.
					if getRingWithState(hellfire, "filled") == nil then
						hellfire.curRing = getRingWithState(hellfire, "empty", true)
					else
						hellfire.curRing = getRingWithState(hellfire, "filled")
					end

					hellfire.transStuff.doFade = true
				end
			end
		end

		--Stop the rest of the OG damage code.
		return true
	end
end

--Little death handler for anything that instantly kills the player.
local function deathHandler(target, cause, src, dmgType)
	if not(target) or not(target.valid) then return end --Non-valid checker
	if target.player.bot and CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.

	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		--Setup the ring variables.
		local targetRing = hellfire.rings[hellfire.curRing]
		local ringAhead = hellfire.rings[hellfire.curRing+1]
		local instaDeath = dmgType == DMG_INSTAKILL or dmgType == DMG_DEATHPIT or dmgType == DMG_CRUSHED or dmgType == DMG_DROWNED or dmgType == DMG_SPACEDROWN or dmgType == DMG_DEATHMASK

		if (instaDeath or hellfire.diedFromHealthLoss == false) and not(isSpecialDeathSkin(ply)) then
			killPlayer(hellfire, false, target, cause, src)
		end
		
		if hellfire.options.doDeathJingle then
			ply.deadtimer = $-TICRATE --The death jingle is just short enough for this to work.
		end
	end
end

--Function to handle refilling health; can handle any ring collections that go above five in one tic (like ring monitors).
local function healthRefillHandler(ply, instaFill, ringsAdded)
	local hellfire = ply.hellfireHealth

	--If there is a ring deficit, put the collected rings towards it instead.
	if hellfire.options.doRingSpill and hellfire.ringDeficit > 0 then
		hellfire.ringDeficit = $-ringsAdded
		return
	end

	--Fetch target health ring.
	local targetRing = hellfire.rings[hellfire.curRing+1]
	if hellfire.rings[hellfire.curRing].state == "empty" then
		targetRing = hellfire.rings[hellfire.curRing]
	end

	local healthBefore = hellfire.health --A bit janky, but it works.
	if hellfire.health < hellfire.maxHealth then --No overheal.
		if instaFill then --Handle any ring changes above five in a tic.
			targetRing.fillAmt = hellfire.fillCap
			hellfire.health = $+1
			if hellfire.curRing < hellfire.maxHealth-1 then
				hellfire.curRing = $+1
				if healthBefore == 1 then hellfire.curRing = $-1 end --A bit janky, but it works.
				S_StartSound(target, sfx_hfgain, ply) --Play the health ring gain sfx.
			end
		else
			if targetRing.fillAmt < hellfire.fillCap-1 then --Any fillAmt below five will increase the fillAmt.
				targetRing.fillAmt = $+ringsAdded
				S_StartSound(target, sfx_hffill, ply) --Play the health ring fill sfx.
			else
				--When fillAmt is five, give a new ring.
				targetRing.fillAmt = hellfire.fillCap
				hellfire.health = $+1
				if hellfire.curRing < hellfire.maxHealth-1 then
					hellfire.curRing = $+1
					if healthBefore == 1 then hellfire.curRing = $-1 end --A bit janky, but it works.
					S_StartSound(target, sfx_hfgain, ply) --Play the health ring gain sfx.
				end
			end
		end
		hellfire.transStuff.doFade = true
	end
end

--Skin comparison function for automatic blocking.
local function isBannedSkin(ply)
	if ply.mo == nil return(true) end

	local skinList = {
		"takisthefox",
		"samus", "basesamus",
		"mario", "luigi",
		"sgimario",
		"doomguy",
	}

	for _,skin in ipairs(skinList) do
		if ply.mo.skin == skin then
			return(true)
		end
	end

	return(false)
end

--The player think handler, misc. junk live here.
local function thkHandler(ply)
	local hellfire = ply.hellfireHealth

	--Check for any characters that mess with health OR fits the skin list.
	if ((ply.mo ~= nil and ply.mo.health ~= 1 and not(hellfire.isDead)) or (isBannedSkin(ply))) and not(hellfire.options.allowOnAllChars) then
		if hellfire.notAllowed == false then
			hellfire.notAllowed = true
		end
	elseif G_IsSpecialStage() and not(hellfire.options.allowOnSpecialStages) then --Check if the current stage is a special stage.
		if hellfire.notAllowed == false then
			hellfire.notAllowed = true
		end
	else
		if hellfire.notAllowed == true then
			hellfire.notAllowed = false
		end
	end

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if hellfire.maxHealth > 1 then --Obviously, this code can only work if there is any health to refill, since the last ring can't.
			for i=1,#hellfire.rings do
				--Catch anytime the fillAmt hits the cap and change their state AND trigger the flash animation.
				if hellfire.rings[i].fillAmt == hellfire.fillCap then
					if hellfire.rings[i].state ~= "filled" then
						hellfire.rings[i].state = "filled"
						hellfire.rings[i].doFlash = true
					end
				end
			end

			--This is where the refill handler is called, and ring difference is kept track.
			if ply.rings ~= hellfire.lastRingCount then
				if ply.rings > hellfire.lastRingCount then --ONLY on ring gain.
					local isOverCap = (ply.rings-hellfire.lastRingCount) >= hellfire.fillCap
					healthRefillHandler(ply, isOverCap, (ply.rings-hellfire.lastRingCount))
				end

				ply.hellfireHealth.lastRingCount = ply.rings
			end
		end
	end
end

--Had to put in manual scaling for the four functions below, since SRB2's scaling seems to be garbage.
--Setting up a function to pre-multiply the positions in drawScaled.
local function scaledDraw_MultPos(v, x, y, scale, patch, flags, colormap)
	if flags == nil then flags = 0 end
	if colormap == nil then colormap = v.getColormap(TC_DEFAULT) end

	v.drawScaled((FU*x)*v.dupx(), (FU*y)*v.dupx(), scale, patch, V_NOSCALESTART|flags)
end

--Setting up a function to pre-multiply the values in drawCropped AND make a simpler function for my needs.
local function simpleCroppedDraw(v, x, y, scale, patch, flags, w, h)
	if flags == nil then flags = 0 end

	v.drawCropped((FU*x)*v.dupx(), (FU*y)*v.dupx(), scale, scale, patch, V_NOSCALESTART|flags, v.getColormap(TC_DEFAULT), w, h, w*FU, h*FU)
end

--Setting up a function to pre-multiply the values in drawStretched AND make a simpler function for my needs.
local function simpleStretchedDraw(v, x, y, scale, patch, width, height, flags)
	if flags == nil then flags = 0 end

	v.drawStretched((FU*x)*v.dupx(), (FU*y)*v.dupx(), (scale*width), (scale*height), patch, V_NOSCALESTART|flags, v.getColormap(TC_DEFAULT))
end

--The built-in drawFill isn't enough for my purposes, so I'm making my own! (It turned out to be simpler to make than I thought.)
local function boxDraw(v, x, y, width, height, flags)
	if flags == nil then flags = 0 end

	local patch = v.getSpritePatch("HFBP")

	v.drawStretched((FU*x)*v.dupx(), (FU*y)*v.dupx(), (FU*width)/5, (FU*height)/2, patch, V_NOSCALESTART|flags, v.getColormap(TC_DEFAULT))
end

--Making my own animation handler.
local function animateObj(i, target, tics, ticRate, startFrame, endFrame, onCompleteFunc)
	local frameDiff = 1
	if target.frame ~= startFrame and target.isAnimating == false then target.frame = startFrame end --Set the frame to the starting frame in the args.
	if startFrame < endFrame and target.isAnimating == false then frameDiff = -1 end --Set the frame advance to negative if the starting frame is less than ending frame.
	target.isAnimating = true --Ensures that animations only play once and don't play over each other.

	--Stop the animation if it's hit the endFrame.
	if target.frame >= endFrame then
		target.frame = endFrame
		target.isAnimating = false

		--A little something to allow code execution after animation completion.
		if onCompleteFunc ~= nil then
			onCompleteFunc()
		end
	elseif target.frame < endFrame then
		if tics % ticRate == 0 then
			target.frame = $+frameDiff
		end
	end
end

--This is where the HUD is drawn.
local function hudHandler(hudDrawer, ply)
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		--Alpha stuff (for fading in/out the HUD).
		local hudTrans = 0
		if hellfire.isDead then
			if hellfire.transStuff.isFadingHUD == false then
				hellfire.transStuff.isFadingHUD = true
				hellfire.transStuff.overallAlpha = 5
			end
			if ply.jointime % 2 == 0 then
				if hellfire.transStuff.overallAlpha >= 1 then
					hellfire.transStuff.overallAlpha = $-1
				end
			end
		elseif ply.exiting then
			if hellfire.transStuff.isFadingHUD == false then
				hellfire.transStuff.isFadingHUD = true
				hellfire.transStuff.overallAlpha = 5
			end

			if ply.jointime % 2 == 0 then
				if hellfire.transStuff.overallAlpha < 10 then
					hellfire.transStuff.overallAlpha = $+1
				end
			end
		elseif hellfire.transStuff.doFade then
			if hellfire.transStuff.isFadingHUD == false then
				hellfire.transStuff.isFadingHUD = true
				hellfire.transStuff.overallAlpha = 5
			end
			if ply.jointime % 1 == 0 then
				if hellfire.transStuff.overallAlpha >= 1 then
					hellfire.transStuff.overallAlpha = $-1
				else
					hellfire.transStuff.doFade = false
					hellfire.transStuff.lastTic = ply.jointime
				end
			end
		else
			if hellfire.transStuff.overallAlpha < 5 and hellfire.transStuff.isFadingHUD then
				if ply.jointime >= hellfire.transStuff.lastTic+(TICRATE*2) then
					if ply.jointime % 1 == 0 then
						if hellfire.transStuff.overallAlpha <= 5 then
							hellfire.transStuff.overallAlpha = $+1
						else
							hellfire.transStuff.isFadingHUD = false
						end
					end
				end
			end
		end

		if hellfire.transStuff.isFadingHUD then
			hudTrans = hellfire.transStuff.overallAlpha<<V_ALPHASHIFT
			if hellfire.transStuff.overallAlpha == 10 or hellfire.transStuff.overallAlpha == 1 then
				hudTrans = V_HUDTRANS
			end
		else
			hudTrans = V_HUDTRANSHALF
			hellfire.transStuff.overallAlpha = 1
		end

		--Stop drawing stuff once the alpha hits the max value.
		if hellfire.transStuff.overallAlpha < 10 then
			local healthPlate = hudDrawer.getSpritePatch("HFHP", hellfire.healthPlate.frame)
			local mainRing = hudDrawer.getSpritePatch("HFMN", hellfire.mainRing.frame)
			local basePos = {x=hudinfo[HUD_RINGS].x-1, y=hudinfo[HUD_RINGS].y+15} --Get the position of the og "RINGS" HUD element and position off of that.

			--Death animation for the base-plate.
			if hellfire.health == 0 and hellfire.healthPlate.animDone == false then
				animateObj(i, hellfire.healthPlate, ply.jointime, 1, 1, 6, function() hellfire.healthPlate.animDone=true end)
			end
			--Getting this correct was a pain, ESPECIALLY since the *2 I put in earlier came back to bite me.
			local ringsWidth = clamp(((8*#hellfire.rings)+((16*2)*#hellfire.rings)), 0, FU)
			if #hellfire.rings >= hellfire.ringWrapAt then
				ringsWidth = clamp(((8*(hellfire.ringWrapAt-1))+((16*2)*(hellfire.ringWrapAt-1))), 0, FU)
			end

			local middle = ((16+4)*hellfire.ringWrapCount)/2
			scaledDraw_MultPos(hudDrawer, basePos.x, basePos.y+middle, FU/2, healthPlate, V_PERPLAYER|hudTrans) --HP Head.

			local boxHeight = 35+(((16+4)*2)*hellfire.ringWrapCount)
			boxDraw(hudDrawer, (basePos.x+(54/2)), basePos.y, ((54/2)+(32*2))+(basePos.x+29), boxHeight, V_PERPLAYER|hudTrans) --Main-Ring backdrop + Half-Rings connector.
			boxDraw(hudDrawer, (basePos.x+54), basePos.y, ringsWidth, boxHeight, V_PERPLAYER|hudTrans) --Half-Rings backdrop.

			--For a while, I couldn't get the position correct, UNTIL I remembered that I divided the boxWidth by 5 in the boxDraw function.
			simpleStretchedDraw(hudDrawer, (basePos.x+54)+(ringsWidth/5), basePos.y+(hellfire.ringWrapCount+(1/3)), FU/2, hudDrawer.getSpritePatch("HFHP", 7), hellfire.endWidth, hellfire.ringWrapCount+1, V_PERPLAYER|hudTrans) --HP End.

			--Ring deficit counter.
			if ply.jointime % 10 == 5 then
				hellfire.ringDefColor = V_REDMAP
			elseif ply.jointime % 10 == 0 then
				hellfire.ringDefColor = V_YELLOWMAP
			end
			if hellfire.ringDeficit > 0 then
				local xOffset = (5*(#tostring(hellfire.ringDeficit)-1))
				hudDrawer.drawString((basePos.x-25)-xOffset, (basePos.y+10)+middle, "-"..hellfire.ringDeficit, V_MONOSPACE|V_PERPLAYER|hudTrans|hellfire.ringDefColor)
			end

			--This is where the rings are drawn.
			for i=1,#hellfire.rings do
				if hellfire.rings[i].doFlash then --Flash/regain animation.
					animateObj(i, hellfire.rings[i], ply.jointime, 1, 6, 10, function()
						hellfire.rings[i].doFlash = false
					end)
				elseif hellfire.rings[i].doShrivel then --Shrivel/loss animation.
					animateObj(i, hellfire.rings[i], ply.jointime, 1, 11, 16, function()
						hellfire.rings[i].frame = 0
						hellfire.rings[i].doShrivel = false
					end)
				else
					--Set the rings to specific frames for their states.
					if hellfire.rings[i].state == "filled" then
						hellfire.rings[i].frame = 10
					elseif hellfire.rings[i].state == "empty" then
						--Use the fillAmt for the animation frames; coded to be modular with different fillCaps.
						if hellfire.fillCap ~= 5 then
							local newFrame = hellfire.rings[i].fillAmt/clamp((hellfire.fillCap/5), 1, FU)
							hellfire.rings[i].frame = newFrame
						else
							hellfire.rings[i].frame = hellfire.rings[i].fillAmt
						end
					end
				end
				local patch = hudDrawer.getSpritePatch("HFHR", hellfire.rings[i].frame)

				scaledDraw_MultPos(hudDrawer, hellfire.rings[i].x, hellfire.rings[i].y, FU/2, patch, V_PERPLAYER|hudTrans)
			end

			--Death animation for the main ring.
			if hellfire.health == 0 and hellfire.mainRing.animDone == false then
				animateObj(i, hellfire.mainRing, ply.jointime, 1, 1, 8, function() hellfire.mainRing.animDone=true end)
			end
			scaledDraw_MultPos(hudDrawer, basePos.x+30, basePos.y+middle, FU/2, mainRing, V_PERPLAYER|hudTrans)
		end
	end
end

--The hooks, which are the last things to execute.
addHook("PlayerSpawn", initHellfire)
addHook("PlayerThink", thkHandler)
addHook("MobjDamage", dmgHandler, MT_PLAYER)
addHook("MobjDeath", deathHandler, MT_PLAYER)
addHook("HUD", hudHandler)

--Funny little compatibilty stuff.
--Orange Demon: Target HP instead.
addHook("TouchSpecial", function(obj, target)
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if obj ~= nil and obj.valid then
			if obj.orangedemon ~= nil and not(obj.orangedemon.cured) then
				if target ~= nil and target.valid and ply and not(target.orangedemon) then
					if obj.orangedemon.delayTill < leveltime then
						P_DamageMobj(obj, target)
						P_DamageMobj(target, obj)
					end
				end
			end
		end

		return true
	end
end, MT_PLAYER)

--Orange Demon: Stop partner AI from picking up rings.
addHook("TouchSpecial", function(obj, target)
	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if obj ~= nil and obj.valid then
			if target.orangedemon ~= nil and not(target.orangedemon.cured) then
				return true
			end
		end
	end
end, MT_RING)