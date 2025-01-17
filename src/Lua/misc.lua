--[[
All of the misc. functions live here.
]]

--Just a clamp function, can be found everywhere at this point.
--Based off of pgimeno's version on the LÖVE board.
--(https://love2d.org/forums/viewtopic.php?t=1856 on page 2)
rawset(_G, "clamp", function(val, minVal, maxVal)
	return(max(minVal, min(maxVal, val)))
end)

--Helper function to return if an object is NOT nil and valid.
rawset(_G, "objectExists", function(obj)
	if obj ~= nil and obj.valid then
		return(true)
	end

	return(false)
end)

--Ring resetter function.
rawset(_G, "resetRings", function(hellfire)
	local basePos = hellfire.basePos

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
end)

rawset(_G, "set_hellfireBoolVar", function(ply, var, newVal, replyTbl)
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
		CONS_Printf(ply, "ERR: \""..tostring(newVal).."\" is nether true nor false.")
	end
end)

rawset(_G, "set_hellfireStrVar", function(ply, var, newVal, valTbl1, valTbl2, replyTbl)
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
		CONS_Printf(ply, "ERR: \""..tostring(newVal).."\" doesn't match any of the specified values.")
	end
end)

--First/last ring with state finder (returns position in table).
rawset(_G, "getRingWithState", function(hellfire, state, doFirst)
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
end)

rawset(_G, "getClientList", function()
	local file = io.openlocal("client/hf_clientList.txt", "r")
	local fileStr = file:read("*a")
	if fileStr == "" or fileStr == nil then
		fileStr = "{}"
	end
	local decoded = hf_json.decode(fileStr)
	file:close()

	return(decoded)
end)

rawset(_G, "modifyClientList", function(skin, tbl)
	local changed = false
	local decoded = getClientList()
	local file = io.openlocal("client/hf_clientList.txt", "w")
	
	if decoded[skin] == nil then
		decoded[skin] = {isBanned=false, shieldHack=false, deathOverride=false}
	end
	
	for key,val in pairs(decoded[skin]) do
		if tbl[key] ~= nil then
			if val ~= tbl[key] then
				changed = true
				decoded[skin][key] = tbl[key]
			end
		end
	end
	
	file:write(hf_json.encode(decoded))
	file:close()
	
	return(changed)
end)

--[[Going to need to revisit these later, I have NO CLUE on how to use io.open properly.
rawset(_G, "fetchServerList", function()
	io.open("hf_serverList.txt", "r", function(file)
		local fileStr = file:read("*a")
		if fileStr == "" or fileStr == nil then
			fileStr = "{}"
		end
		HFSrvList = hf_json.decode(fileStr)
		file:close()
	end)
	
	return(true)
end)

rawset(_G, "flushServerList", function()
	local decoded = HFSrvList
	local file = io.openlocal("hf_serverList.txt", "w")

	file:write(hf_json.encode(decoded))
	file:close()
	
	return(true)
end)
]]

rawset(_G, "modifyServerList", function(skin, tbl)
	local changed = false
	local decoded = HFSrvList
	
	if decoded[skin] == nil then
		decoded[skin] = {isBanned=false}
	end
	
	for key,val in pairs(decoded[skin]) do
		if tbl[key] ~= nil then
			if val ~= tbl[key] then
				changed = true
				decoded[skin][key] = tbl[key]
			end
		end
	end
	
	return(changed)
end)

rawset(_G, "getPrefs", function()
	local file = io.openlocal("client/hf_prefs.txt", "r")

	local prefs = {}
	for line in file:lines() do
		if line:find("^#.+$") == nil and #line > 0 and line ~= "\n" then
			local commentClear = line:gsub("#.+$", "")
			local spaces = commentClear:gsub(" $", "")
			local newlines = spaces:gsub("\n$", "")
			
			local var = newlines:gsub(" = .+", "")
			local value = newlines:gsub(".+ = ", "")
			
			for prefName, trueName in pairs(hfPrefsMapping) do
				if var:lower() == prefName then
					if value:lower() == "true" then
						prefs[trueName] = true
					elseif value:lower() == "false" then
						prefs[trueName] = false
					else
						prefs[trueName] = value:lower()
					end
				end
			end
		end
	end
	file:close()

	return(prefs)
end)

rawset(_G, "getPrefsRaw", function()
	local file = io.openlocal("client/hf_prefs.txt", "r")

	local tbl = {}
	for line in file:lines() do
		table.insert(tbl, line)
	end
	file:close()

	return(tbl)
end)

local function checkEquals(line)
	if line:find(" = ") ~= nil then
		return(" = ")
	elseif line:find(" =") ~= nil then
		return(" =")
	elseif line:find("= ") ~= nil then
		return("= ")
	else
		return("=")
	end
end

rawset(_G, "savePrefs", function(hellfire)
	local tbl = {}
	for _,line in pairs(getPrefsRaw()) do
		if line:find("^#.+$") == nil and #line > 0 and line ~= "\n" then
			local equPattern = checkEquals(line)

			local commentClear = line:gsub("#.+$", "")
			local spaces = commentClear:gsub(" $", "")
			local newlines = spaces:gsub("\n$", "")
			
			local var = newlines:gsub(equPattern+".+", "")
			local value = newlines:gsub(".+"+equPattern, "")
			
			for prefName, trueName in pairs(hfPrefsMapping) do
				if var:lower() == prefName then
					local newValue = hellfire.options[trueName]
					local compLine = line:gsub(equPattern+value, equPattern+tostring(newValue))
					table.insert(tbl, compLine)
				end
			end
		else
			table.insert(tbl, line)
		end
	end
	local newContents = table.concat(tbl, "\n")
	
	local file = io.openlocal("client/hf_prefs.txt", "w")
	file:write(newContents)
	file:close()
end)

--Skin comparison function for characters using shield hacks for their damage system.
rawset(_G, "isShieldHackSkin", function(ply)
	if ply.mo == nil return(true) end
	
	local skinList = getClientList()
	
	for skin,vals in pairs(skinList) do
		if ply.mo.skin == skin then
			return(vals.shieldHack)
		end
	end

	return(false)
end)

--Skin comparison function for characters using unique systems for death.
rawset(_G, "isSpecialDeathSkin", function(ply)
	if ply.mo == nil return(true) end

	local skinList = getClientList()

	for skin,vals in pairs(skinList) do
		if ply.mo.skin == skin then
			return(vals.deathOverride)
		end
	end

	return(false)
end)

--Skin comparison function for automatic blocking.
rawset(_G, "isBannedSkin", function(ply)
	if ply.mo == nil return(true) end

	local clientList = getClientList()
	local serverList = HFSrvList
	
	for skin,vals in pairs(clientList) do
		if ply.mo.skin == skin then
			return(vals.isBanned)
		end
	end

	if CV_FindVar("hellfire_useSrvList").value == 1 and ply.hellfireHealth.bypassServerList == false then
		for skin,vals in pairs(serverList) do
			if ply.mo.skin == skin then
				return(vals.isBanned)
			end
		end
	end

	return(false)
end)

--Bar getter from player.
rawset(_G, "getPlayerBar", function(ply)
	for i,bar in ipairs(HFBars) do
		if objectExists(bar) and objectExists(bar.target)
		and bar.target == ply.mo then
			return bar, i
		end
	end

	return(nil)
end)

--A quick function that removes the bars attached to a player.
rawset(_G, "removePlyBars", function(ply)
	local bar, iter = getPlayerBar(ply)
	if bar ~= nil then
		for _,clone in ipairs(bar.clones) do
			P_RemoveMobj(clone)
			clone = nil
		end

		P_RemoveMobj(bar)
		bar = nil
	end

	table.remove(HFBars, iter)
end)

--A quick function that removes all bars from the game.
rawset(_G, "removeAllBars", function()
	for _,bar in ipairs(HFBars) do
		if objectExists(bar) then
			for _,clone in ipairs(bar.clones) do
				if objectExists(clone) then
					P_RemoveMobj(clone)
					clone = nil
				end
			end

			P_RemoveMobj(bar)
			bar = nil
		end
	end
	
	HFBars = {}
end)

--A little function that will try all three moving functions to keep compatibility with pre-2.2.11.
rawset(_G, "hfMoveMobj", function(mobj, x, y, z)
	if pcall(P_MoveOrigin, mobj, x, y, z) ~= true then
		if pcall(P_SetOrigin, mobj, x, y, z) ~= true then
			P_TeleportMove(mobj, x, y, z)
		end
	end
end)

rawset(_G, "loadPrefs", function(ply)
	local hellfire = ply.hellfireHealth

	for var,val in pairs(getPrefs()) do
		local finalVal = val
		if var == "skin" then
			if finalVal ~= "red" and finalVal ~= "yellow" then
				CONS_Printf(ply, '\x85"'..tostring(finalVal)..'"'.." isn't a valid option, so it has been set to the default.")
				finalVal = "red"
			end
		end
		if var == "doDeathJingle" or var == "seeHealth" or var == "autoSave" then
			if finalVal ~= true and finalVal ~= false then
				CONS_Printf(ply, '\x85"'..tostring(finalVal)..'"'.." isn't a valid option, so it has been set to the default.")
				finalVal = true
			end
		end

		hellfire.options[var] = finalVal
	end
end)

--Damage function for mappers.
rawset(_G, "hf_directDmg", function(ply, dmg, scales, silent)
	local hellfire = ply.hellfireHealth

	local trueTbl = {"true", "1", "on"}
	local falseTbl = {"false", "0", "off"}

	--You can't outright kill the player!
	if hellfire.health == 1 then
		return
	end
	
	dmg = tonumber($)
	if dmg == nil then dmg = 1 end

	if type(scales) == "string" then
		if table.concat(trueTbl, " "):find(scales:lower()) then
			scales = true
		elseif table.concat(falseTbl, " "):find(scales:lower())
			scales = false
		else
			scales = false
		end
	end
	
	if scales then
		if hellfire.maxHealth > 5 then
			dmg = clamp($, 0, 4)
			
			if dmg == 1 then
				dmg = hellfire.maxHealth/4
			elseif dmg == 2 then
				dmg = hellfire.maxHealth/3
			elseif dmg == 3 then
				dmg = hellfire.maxHealth/2
			elseif dmg == 4 then
				dmg = hellfire.maxHealth-1
			end
		end
	else
		--You can't outright kill the player!
		dmg = clamp($, 0, hellfire.maxHealth-1)
	end

	if ply.powers[pw_flashing] <= 0 then
		if dmg > 1 then
			for i=0,dmg-2 do
				if hellfire.curRing == 1 then break end

				local targetRing = hellfire.rings[hellfire.curRing]
				local ringAhead = hellfire.rings[hellfire.curRing+1]

				targetRing.fillAmt = 0
				targetRing.state = "empty"
				targetRing.doShrivel = true --Do ring loss animation
				if ringAhead ~= nil and ringAhead.fillAmt > 0 then --Remove any progress on next ring.
					ringAhead.fillAmt = 0
				end

				hellfire.transStuff.doFade = true

				hellfire.curRing = $-1
			end
		end
		
		hellfire.health = clamp($-(dmg-1), 2, hellfire.maxHealth)
		P_DamageMobj(ply.mo)
	end
end)

--Healing function for mappers.
rawset(_G, "hf_directHeal", function(ply, newHlth, scales, silent)
	local hellfire = ply.hellfireHealth

	local trueTbl = {"true", "1", "on"}
	local falseTbl = {"false", "0", "off"}

	--No overheal!
	if hellfire.health == hellfire.maxHealth then
		return
	end
	
	newHlth = tonumber($)
	if newHlth == nil then newHlth = 1 end

	if type(scales) == "string" then
		if table.concat(trueTbl, " "):find(scales:lower()) then
			scales = true
		elseif table.concat(falseTbl, " "):find(scales:lower())
			scales = false
		else
			scales = false
		end
	end

	if scales then
		if hellfire.maxHealth > 5 then
			newHlth = clamp($, 0, 4)

			if newHlth == 1 then
				newHlth = hellfire.maxHealth/4
			elseif newHlth == 2 then
				newHlth = hellfire.maxHealth/3
			elseif newHlth == 3 then
				newHlth = hellfire.maxHealth/2
			elseif newHlth == 4 then
				newHlth = hellfire.maxHealth-1
			end
		end
	else
		--Ensures no overheal occurs.
		newHlth = clamp($, 0, hellfire.maxHealth)
	end

	for i=0,newHlth do
		local targetRing = hellfire.rings[hellfire.curRing]

		targetRing.fillAmt = hellfire.fillCap
		hellfire.curRing = clamp($+1, 0, hellfire.maxHealth-1)
	end
	
	S_StartSound(target, sfx_hfgain, ply) --Play the health ring gain sfx.

	--Yes, I'm putting in a LOT of these clamps.
	hellfire.health = clamp($+newHlth, 0, hellfire.maxHealth)
	hellfire.transStuff.doFade = true
end)