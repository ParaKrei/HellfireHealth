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
		print("ERR: \""..tostring(newVal).."\" is nether true nor false.")
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
		print("ERR: \""..tostring(newVal).."\" doesn't match any of the specified values.")
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
	local decoded = json.decode(fileStr)
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
	
	file:write(json.encode(decoded))
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
		HFSrvList = json.decode(fileStr)
		file:close()
	end)
	
	return(true)
end)

rawset(_G, "flushServerList", function()
	local decoded = HFSrvList
	local file = io.openlocal("hf_serverList.txt", "w")

	file:write(json.encode(decoded))
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
		if bar ~= nil then
			for _,clone in ipairs(bar.clones) do
				P_RemoveMobj(clone)
				clone = nil
			end

			P_RemoveMobj(bar)
			bar = nil
		end
	end
	
	HFBars = {}
end)