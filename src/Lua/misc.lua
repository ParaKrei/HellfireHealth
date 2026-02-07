--[[
	All of the misc. functions live here.
]]

--Just a clamp function, can be found everywhere at this point.
--Based off of pgimeno's version on the LÖVE board.
--(https://love2d.org/forums/viewtopic.php?t=1856 on page 2)
hf["clamp"] = function(val, minVal, maxVal)
	return(max(minVal, min(maxVal, val)))
end
local clamp = hf.clamp --Required for local calls

--An amazing non-fallthrough switch statement.
--Tweaked by ParaKrei to insert the ability to call another case to avoid reusing code.
--Original made by Krystilize, from Stack Overflow; CC BY-SA 4.0
--(https://stackoverflow.com/a/65047878)
--New usage: Works like the original, but putting in another case into a string into where a function goes will call that case's function.
hf["switch"] = function(element)
	local Table = {
		["Value"] = element,
		["DefaultFunction"] = nil,
		["Functions"] = {}
	}

	Table.case = function(testElement, callback)
		Table.Functions[testElement] = callback
		return Table
	end

	Table.default = function(callback)
		Table.DefaultFunction = callback
		return Table
	end

	Table.process = function()
		local Case = Table.Functions[Table.Value]

		if type(Table.Functions[Case]) == "function" then
			Table.Functions[Case]()
		elseif Case then
			Case()
		elseif Table.DefaultFunction then
			Table.DefaultFunction()
		end
	end

	return Table
end
local switch = hf.switch --Required for local calls

--An iterator like pair(), but sorted by the table's keys.
--Taken straight from the Lua manual.
--(https://www.lua.org/pil/19.3.html)
hf["pairsByKeys"] = function(tbl, sortFunc)
	local sorted = {}

	for key in pairs(tbl) do table.insert(sorted, key) end
	table.sort(sorted, sortFunc)

	local i = 0
	local iterFunc = function()
		i = i+1

		if sorted[i] == nil then return nil
		else return sorted[i], tbl[sorted[i]] end
	end

	return iterFunc
end

--Helper function to directly compare tables to see if they are EXACT matches.
--Made by TomatoCo
--(https://www.reddit.com/r/lua/comments/417v44/efficient_table_comparison/)
--[Look, it was 1AM when I was looking for a table comparison function,
--I'm not going to make my own function, especially when this does exactly what I want.]
hf["tableCompare"] = function(tbl1, tbl2)
	if #tbl1 ~= #tbl2 then return false end

	local t1, t2 = {}, {}

	--Make local copies.
	for key,val in pairs(tbl1) do
		t1[key] = (t1[key] or 0)+1 --Count the times we've seen the same value.
	end
	for key,val in pairs(tbl2) do
		t2[key] = (t2[key] or 0)+1
	end

	for key,val in pairs(t1) do
		if val ~= t2[key] then return false end
	end

	return true
end

--Helper function to return if a string matches any entries in a table.
hf["isStringInTbl"] = function(str, tbl)
	for _,val in pairs(tbl) do
		if tostring(str):lower() == tostring(val):lower() then
			return true
		end
	end
	return false
end
local isStringInTbl = hf.isStringInTbl --Required for local calls

--Helper function to return if a string represents true or false.
hf["strToBool"] = function(str)
	local trueTbl = {"true", "1", "on"}
	local falseTbl = {"false", "0", "off"}

	if isStringInTbl(str, trueTbl) then
		return true
	elseif isStringInTbl(str, falseTbl) then
		return false
	end

	return nil
end
local strToBool = hf.strToBool --Required for local calls

--Helper function to return if an object is NOT nil and valid.
hf["objectExists"] = function(obj)
	if obj ~= nil and obj.valid then
		return true
	end

	return false
end
local objectExists = hf.objectExists --Required for local calls

--Helper function to return if any game control is pressed through the input library.
hf["anyGameControlDown"] = function(targetP2)
	if targetP2 == nil then targetP2 = false end

	local func = input.gameControlDown
	if targetP2 then func = input.gameControl2Down end

	for i=1,NUM_GAMECONTROLS-1 do
		if func(i) then return true end
	end

	return false
end
--Helper function to return all pressed game controls through the input library.
hf["getAllPressedGameControls"] = function(targetP2)
	if targetP2 == nil then targetP2 = false end

	local func = input.gameControlDown
	if targetP2 then func = input.gameControl2Down end

	local tbl = {}
	for i=1,NUM_GAMECONTROLS-1 do
		if func(i) then table.insert(tbl, i) end
	end

	return tbl
end

--Helper function to check if a player is an admin; also catches if the player is the host.
hf["isAdmin"] = function(ply)
	if IsPlayerAdmin(ply) then return true end
	if isserver then return true end
	return false
end

--Helper function to check if a player can be hurt.
hf["canPlayerBeHurt"] = function(ply, debug)
	if debug then
		print("Is player invulnerable? "..tostring(ply.powers[pw_invulnerability] ~= 0))
		print("Is player flashing? "..tostring(ply.powers[pw_flashing] ~= 0))
		print("Is player super? "..tostring(ply.powers[pw_super] ~= 0))
		print("Does player have STR_GUARD? "..tostring(ply.powers[pw_strong] & STR_GUARD ~= 0))
		print("Is player in pain? "..tostring(P_PlayerInPain(ply)))
	end

	if ply.powers[pw_invulnerability] or
	ply.powers[pw_flashing] or
	ply.powers[pw_super] or
	(ply.powers[pw_strong] & STR_GUARD) or
	P_PlayerInPain(ply) then
		return false
	end

	return true
end

--A little function to quickly make draw commands with object-like data.
hf["dataDraw"] = function(v, drawType, obj)
	if obj.patch == nil then obj.patch = v.getSpritePatch("UNKN") end
	if obj.flags == nil then obj.flags = 0 end
	if obj.x == nil then obj.x = 0 end
	if obj.y == nil then obj.y = 0 end
	if obj.colormap == nil then obj.colormap = v.getColormap(TC_DEFAULT) end --Just in case.
	
	if (type(drawType) == "string" and (drawType:lower() == "normal" or drawType:lower() == "n") or (tonumber(drawType) ~= nil and tonumber(drawType) == 0)) then
		v.draw(obj.x, obj.y, obj.patch, obj.flags, obj.colormap)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "scaled" or drawType:lower() == "sc") or (tonumber(drawType) ~= nil and tonumber(drawType) == 1)) then
		if obj.scale == nil then obj.scale = FU end

		v.drawScaled(obj.x, obj.y, obj.scale, obj.patch, obj.flags, obj.colormap)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "stretched" or drawType:lower() == "st") or (tonumber(drawType) ~= nil and tonumber(drawType) == 2)) then
		if obj.scale == nil then obj.scale = {x=FU, y=FU} end
		if obj.scale.x == nil then obj.scale.x = FU end
		if obj.scale.y == nil then obj.scale.y = FU end

		v.drawStretched(obj.x, obj.y, obj.scale.x, obj.scale.y, obj.patch, obj.flags, obj.colormap)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "cropped" or drawType:lower() == "c") or (tonumber(drawType) ~= nil and tonumber(drawType) == 3)) then
		if obj.scale == nil then obj.scale = {x=FU, y=FU} end
		if obj.scale.x == nil then obj.scale.x = FU end
		if obj.scale.y == nil then obj.scale.y = FU end
		if obj.crop == nil then obj.crop = {x=FU, y=FU} end
		if obj.crop.x == nil then obj.crop.x = FU end
		if obj.crop.y == nil then obj.crop.y = FU end
		if obj.width == nil then obj.width = FU end
		if obj.height == nil then obj.height = FU end

		v.drawCropped(obj.x, obj.y, obj.scale.x, obj.scale.y, obj.patch, obj.flags, obj.colormap, obj.crop.x, obj.crop.y, obj.width, obj.height)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "string" or drawType:lower() == "str" or drawType:lower() == "text" or drawType:lower() == "txt") or (tonumber(drawType) ~= nil and tonumber(drawType) == 4)) then
		if obj.text == nil then obj.text = "" end
		if obj.align == nil then obj.align = "left" end

		v.drawString(obj.x, obj.y, obj.text, obj.flags, obj.align)
		return true
	end

	return false
end

--Making my own animation handler.
hf["animateObj"] = function(target, time, args, onCompleteFunc, debug)
	if debug == nil then debug = false end
	if args == nil then args = {} end
	if args.ticsPerFrame == nil then args.ticsPerFrame = 1 end
	if args.frames == nil then args.frames = {1,1} end
	if args.reverse == nil then args.reverse = false end

	if args.frames[1] > args.frames[2] then
		if debug then
			print("warning: the first frame is bigger than the last frame.")
			print("flipping the frames around and turning on reverse...")
		end
		args.frames = {args.frames[2], args.frames[1]}
		args.reverse = true
	end

	if not(target.isAnimating) then
		if not(args.reverse) and target.frame ~= args.frames[1] then target.frame = args.frames[1] end --Set the frame to the starting frame in the args.
		if args.reverse and target.frame ~= args.frames[2] then target.frame = args.frames[2] end --Set the frame to the ending frame in the args.
		if debug then print("starting on frame "..tostring(target.frame)) end
		target.isAnimating = true --Ensures that animations only play once and don't play over each other.

		if target.lastTic == nil then target.lastTic = time end --Set lastTic to what time is on the first frame.
	end

	--Stop the animation if it's hit the whatever the ending frame is.
	if (not(args.reverse) and target.frame >= args.frames[2]) or (args.reverse and target.frame <= args.frames[1]) then
		if not(args.reverse) then target.frame = args.frames[2] elseif args.reverse then target.frame = args.frames[1] end
		if debug then print("anim finished; is reverse? "..tostring(args.reverse)..", cur frame == "..tostring(target.frame)..", start frame == "..tostring(args.frames[1])..", end frame == "..tostring(args.frames[2])) end
		target.isAnimating = false
		target.lastTic = nil

		--A little something to allow code execution after animation completion.
		if onCompleteFunc ~= nil then onCompleteFunc() end
		return
	elseif (not(args.reverse) and target.frame ~= args.frames[2]) or (args.reverse and target.frame ~= args.frames[1]) then
		if time-target.lastTic >= args.ticsPerFrame then
			if debug then print("lastTic == "..tostring(target.lastTic)..", current tic == "..tostring(time)) end

			if args.reverse then
				target.frame = $-1 --Decrement frame.
			else
				target.frame = $+1 --Increment frame.
			end

			target.lastTic = time --Set lastTic to current tic.
		end
	end
end

--Hook injector, for when addHook isn't enough.
--Only MobjDamage and MobjDeath is supported right now.
--REQUIRES switch.
hf["injectHook"] = function(hook, func)
	if hook == nil then print("ERROR: A hook name is needed to inject!") return false end

	switch(hook:lower())
		.case("dmg", "mobjdamage")
		.case("damage", "mobjdamage")
		.case("objdmg", "mobjdamage")
		.case("objdamage", "mobjdamage")
		.case("mobjdmg", "mobjdamage")
		.case("mobjdamage", function()
			if hf.compat.MobjDamage == nil then hf.compat.MobjDamage = {} end
			table.insert(hf.compat.MobjDamage, func)
		end)
		.case("dth", "mobjdeath")
		.case("death", "mobjdeath")
		.case("objdth", "mobjdeath")
		.case("objdeath", "mobjdeath")
		.case("mobjdth", "mobjdeath")
		.case("mobjdeath", function()
			if hf.compat.MobjDeath == nil then hf.compat.MobjDeath = {} end
			table.insert(hf.compat.MobjDeath, func)
		end)
	.process()
end

--Ring resetter function.
hf["resetRings"] = function(hellfire, custom)
	local basePos = hellfire.basePos
	local targetVal = hellfire.maxHealth
	if custom ~= nil then targetVal = custom end

	hellfire.rings = {} --Clear rings table.
	hellfire.ringWrapCount = 0 --Clear wrap count.
	hellfire.ringXOffset = 0 --Reset offset.
	hellfire.ringWrapOffset = 0 --Reset wrap offset.
	hellfire.endWidth = 1 --Reset end cap width.

	for i=1,targetVal-1 do
		local tbl = { --state: 1 = filled, 0 = empty; doAnim: -1 = none, 0 = shrivel, 1 = flash, 2 = slow reverse flash
			fillAmt=hellfire.fillCap, state=1, doAnim=-1,
			frame=0, isAnimating=false, lastTic=nil,
			x=0, y=0
		}
		hellfire.rings[i] = tbl

		--Position code.
		hellfire.ringXOffset = $+8
		if i % hellfire.ringWrapAt == hellfire.ringWrapOffset then
			if hellfire.ringWrapOffset == 0 then
				hellfire.ringWrapOffset = hellfire.ringWrapAt-1
			else
				hellfire.ringWrapOffset = $-1
			end

			hellfire.ringWrapCount = $+1
			hellfire.ringXOffset = 8
			if (hellfire.ringWrapCount % 2 == 0) then hellfire.endWidth = $+1 end
		end

		hellfire.rings[i].x = (basePos.x+40)+hellfire.ringXOffset
		hellfire.rings[i].y = basePos.y+(hellfire.ringYOffset*hellfire.ringWrapCount)
	end
end
local resetRings = hf.resetRings --Required for local calls

hf["set_hellfireBoolVar"] = function(ply, var, newVal, replyTbl, silent, onlyChanged)
	local noChange = false
	local finalVal = strToBool(newVal)

	if finalVal == nil then
		CONS_Printf(ply, "\x85\bThe value \""..tostring(newVal).."\" is NOT \"\x82\bfalse\x85\", \"\x82\btrue\x85\", \"\x82\b0\x85\", \"\x82\b1\x85\", \"\x82\bon\x85\", or \"\x82\boff\x85\"!")
		return true, false
	elseif finalVal == true then
		local lastVal = ply.hellfireHealth.options[var]
		ply.hellfireHealth.options[var] = true
		if ply.hellfireHealth.options[var] == lastVal then noChange = true end

		if replyTbl ~= nil then
			if onlyChanged and noChange then return noChange end
			if not(silent) then CONS_Printf(ply, replyTbl.trueStatement) end
		end
	elseif finalVal == false then
		local lastVal = ply.hellfireHealth.options[var]
		ply.hellfireHealth.options[var] = false
		if ply.hellfireHealth.options[var] == lastVal then noChange = true end
		
		if replyTbl ~= nil then
			if onlyChanged and noChange then return noChange end
			if not(silent) then CONS_Printf(ply, replyTbl.falseStatement) end
		end
	end

	return noChange, true
end

hf["set_hellfireStrVar"] = function(ply, var, newVal, valTbl1, valTbl2, replyTbl, silent, onlyChanged)
	local noChange = false
	local finalVal = nil
	
	if isStringInTbl(newVal, valTbl1.values) then
		finalVal = 1
	elseif isStringInTbl(newVal, valTbl2.values) then
		finalVal = 2
	end

	if finalVal == nil then
		CONS_Printf(ply, "\x85\bThe value \""..tostring(newVal).."\" doesn't match any of the specified values.")
		return true, false
	elseif finalVal == 1 then
		local lastVal = ply.hellfireHealth.options[var]
		ply.hellfireHealth.options[var] = valTbl1.returnVal
		if ply.hellfireHealth.options[var] == lastVal then noChange = true end

		if replyTbl ~= nil then
			if onlyChanged and noChange then return noChange end
			if not(silent) then CONS_Printf(ply, replyTbl.statement1) end
		end
	elseif finalVal == 2 then
		local lastVal = ply.hellfireHealth.options[var]
		ply.hellfireHealth.options[var] = valTbl2.returnVal
		if ply.hellfireHealth.options[var] == lastVal then noChange = true end

		if replyTbl ~= nil then
			if onlyChanged and noChange then return noChange end
			if not(silent) then CONS_Printf(ply, replyTbl.statement2) end
		end
	end

	return noChange, true
end

--First/last ring with state finder (returns ring).
hf["getRingWithState"] = function(hellfire, state, doFirst)
	if doFirst == nil then doFirst = false end

	if doFirst then
		for i=1,#hellfire.rings do
			if hellfire.rings[i].state == state then
				return(hellfire.rings[i])
			end
		end
	else
		for i=#hellfire.rings,1,-1 do
			if hellfire.rings[i].state == state then
				return(hellfire.rings[i])
			end
		end
	end

	return(nil)
end
--Counts the amount of rings with the target state; returns the count and if there are any gaps.
hf["countRingsWithState"] = function(hellfire, state)
	local count = 0
	local gap = false

	for i=1,#hellfire.rings do
		if hellfire.rings[i].state == state then
			count = $+1

			if hellfire.rings[i-1] ~= nil and hellfire.rings[i-1].state ~= state then
				gap = true
			end
		end
	end

	return count, gap
end

hf["getClientList"] = function()
	local file = io.openlocal("client/hf_clientList.txt", "r")
	local fileStr = file:read("*a")
	if fileStr == "" or fileStr == nil then
		fileStr = "{}"
	end
	local decoded = hf["json"].decode(fileStr)
	file:close()

	return(decoded)
end
local getClientList = hf.getClientList --Required for local calls

--Checks if a table contains a value.
hf["tableContains"] = function(table, target)
	for key,val in pairs(table) do
		if val == target return true end
	end

	return false
end
local tableContains = hf["tableContains"] --Required for local calls

hf["modifyClientList"] = function(skin, tbl)
	local changed = false
	local removed = false
	local decoded = getClientList()
	local file = io.openlocal("client/hf_clientList.txt", "w")
	
	if decoded[skin] == nil then
		decoded[skin] = {isBanned=false, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false}
	end
	if tbl == nil then tbl = {isBanned=false, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false} end
	
	--Apply to existing settings.
	for key,val in pairs(decoded[skin]) do
		if tbl[key] ~= nil then
			if val ~= tbl[key] then
				changed = true
				decoded[skin][key] = tbl[key]
			end
		end
	end

	--Add new settings.
	for key,val in pairs(tbl) do
		if decoded[skin][key] == nil then
			changed = true
			decoded[skin][key] = tbl[key]
		end
	end

	--Remove the entry IF all entries are false
	if decoded[skin] ~= nil and not(tableContains(decoded[skin], true)) then
		decoded[skin] = nil --Suprisingly, this works.
		removed = true
	end
	
	file:write(hf["json"].encode(decoded))
	file:close()
	
	return changed, removed
end

hf["modifyServerList"] = function(skin, tbl)
	local changed = false
	local nils = {false, false}
	
	if hf["srvList"][skin] == nil then hf["srvList"][skin] = {serverBanned=false}; nils[1]=true end
	if tbl == nil then tbl = {serverBanned=false}; nils[2]=true end

	if nils[1] and nils[2] then changed = true end
	
	--Set stuff
	for key,val in pairs(hf["srvList"][skin]) do
		if tbl[key] ~= nil then
			if val ~= tbl[key] then
				changed = true
				hf["srvList"][skin][key] = tbl[key]
			end
		end
	end
	
	return changed
end

hf["getPrefs"] = function()
	local file = io.openlocal("client/hf_prefs.txt", "r")

	local prefs = {}
	for line in file:lines() do
		if line:find("^#.+$") == nil and #line > 0 and line ~= "\n" then
			local commentClear = line:gsub("#.+$", "")
			local spaces = commentClear:gsub(" $", "")
			local newlines = spaces:gsub("\n$", "")
			
			local var = newlines:gsub(" = .+", "")
			local value = newlines:gsub(".+ = ", "")
			
			for prefName, trueName in pairs(hf["prefsMapping"]) do
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
end
local getPrefs = hf.getPrefs --Required for local calls

hf["getPrefsRaw"] = function()
	local file = io.openlocal("client/hf_prefs.txt", "r")

	local tbl = {}
	for line in file:lines() do
		table.insert(tbl, line)
	end
	file:close()

	return(tbl)
end
local getPrefsRaw = hf.getPrefsRaw --Required for local calls

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

hf["savePrefs"] = function(ply)
	if ply ~= consoleplayer then return end

	--Reset prefs file to ensure all variables are properly saved.
	local file = io.openlocal("client/hf_prefs.txt", "w")
	file:write(hf.defaultPrefs)
	file:close()

	local hellfire = ply.hellfireHealth

	local tbl = {}
	for _,line in pairs(getPrefsRaw()) do
		if line:find("^#.+$") == nil and #line > 0 and line ~= "\n" then
			local equPattern = checkEquals(line)

			local commentClear = line:gsub("#.+$", "")
			local spaces = commentClear:gsub(" $", "")
			local newlines = spaces:gsub("\n$", "")
			
			local var = newlines:gsub(equPattern+".+", "")
			local value = newlines:gsub(".+"+equPattern, "")
			
			for prefName, trueName in pairs(hf["prefsMapping"]) do
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
end

hf["getHUDPresets"] = function()
	local file = io.openlocal("client/hf_hudPresets.txt", "r")
	local fileStr = file:read("*a")
	if fileStr == "" or fileStr == nil then
		fileStr = "{}"
	end
	local decoded = hf["json"].decode(fileStr)
	file:close()

	return(decoded)
end
local getHUDPresets = hf.getHUDPresets --Required for local calls

hf["modifyHUDPresets"] = function(num, tbl)
	local changed = false
	local removed = false
	local decoded = getHUDPresets()
	local file = io.openlocal("client/hf_hudPresets.txt", "w")
	
	if decoded[num] == nil then decoded[num] = {x = 0, y = 0} end
	if tbl == nil then tbl = {x = 0, y = 0} end
	if tbl.x == nil then tbl.x = 0 end
	if tbl.y == nil then tbl.y = 0 end
	
	--Apply new coordinates.
	for key,val in pairs(tbl) do
		if val ~= decoded[num][key] then
			changed = true
			decoded[num][key] = tbl[key]
		end
	end
	
	file:write(hf["json"].encode(decoded))
	file:close()
	
	return changed, removed
end

--Skin comparison function to fetch any specific changes needed.
hf["getSkinVar"] = function(ply, var)
	if ply.mo == nil return true end

	local skinList = getClientList()

	for skin,vals in pairs(skinList) do
		if ply.mo.skin == skin then
			return(vals[var])
		end
	end

	if CV_FindVar("hellfire_useSrvList").value == 1 and ply.hellfireHealth.bypassServerList == false then
		for skin,vals in pairs(hf["srvList"]) do
			if ply.mo.skin == skin then
				return(vals[var])
			end
		end
	end

	return false
end

--Bar getter from player.
hf["getPlayerBar"] = function(ply)
	for i,bar in ipairs(hf["bars"]) do
		if objectExists(bar) and objectExists(bar.target)
		and bar.target == ply.mo then
			return bar, i
		end
	end

	return(nil)
end
local getPlayerBar = hf.getPlayerBar --Required for local calls

--A quick function that removes the bars attached to a player.
hf["removePlyBars"] = function(ply)
	local bar, iter = getPlayerBar(ply)
	if bar ~= nil then
		for _,clone in ipairs(bar.clones) do
			P_RemoveMobj(clone)
			clone = nil
		end

		P_RemoveMobj(bar)
		bar = nil
	end

	table.remove(hf["bars"], iter)
end

--A quick function that removes all bars from the game.
hf["removeAllBars"] = function()
	for _,bar in ipairs(hf["bars"]) do
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
	
	hf["bars"] = {}
end

--A little function that will try all three moving functions to keep compatibility with pre-2.2.11.
hf["moveMobj"] = function(mobj, x, y, z)
	if pcall(P_MoveOrigin, mobj, x, y, z) ~= true then
		if pcall(P_SetOrigin, mobj, x, y, z) ~= true then
			P_TeleportMove(mobj, x, y, z)
		end
	end
end

hf["loadHUDPreset"] = function(ply, num)
	if num == nil then num = ply.hellfireHealth.options.presetNum end

	ply.hellfireHealth.basePos = hf.getHUDPresets()[num]
	resetRings(ply.hellfireHealth)
end
local loadHUDPreset = hf.loadHUDPreset --Required for local calls

hf["loadPrefs"] = function(ply)
	if ply ~= consoleplayer then ply.hellfireHealth.prefsLoaded = true return end

	local hellfire = ply.hellfireHealth

	for var,val in pairs(getPrefs()) do
		local finalVal = val
		if var == "skin" then
			if finalVal ~= "red" and finalVal ~= "yellow" then
				CONS_Printf(ply, '\x85"'..tostring(finalVal)..'"'.." isn't a valid option, so it has been set to the default.")
				finalVal = "red"
			end
		end
		if var == "doDeathJingle" or var == "seeHealth" or var == "autoSave" or var == "meltRing" then
			if finalVal ~= true and finalVal ~= false then
				CONS_Printf(ply, '\x85"'..tostring(finalVal)..'"'.." isn't a valid option, so it has been set to the default.")
				finalVal = true
			end
		end

		hellfire.options[var] = finalVal
	end

	loadHUDPreset(ply)

	ply.hellfireHealth.prefsLoaded = true
end

--Damage function for mappers.
hf["directDmg"] = function(ply, dmg, args)
	if dmg == nil then dmg = 1 end
	if args == nil then args = {} end
	if args.division == nil then args.division = false end
	if args.silent == nil then args.silent = false end
	if args.forceSound == nil then args.forceSound = false end
	if args.instant == nil then args.instant = false end
	if args.pain == nil then args.pain = true end
	if args.loss == nil then args.loss = true end

	local hellfire = ply.hellfireHealth
	
	--You can't outright kill the player!
	if hellfire.health == 1 then return end
	
	dmg = tonumber($)
	if dmg == nil then dmg = 1 end
	if dmg == 0 then return end --You aren't even dealing any damage!
	if type(args.division) == "string" then
		args.division = strToBool($)
		if args.division == nil then args.division = false end --Fallback
	end
	if type(args.silent) == "string" then
		args.silent = strToBool($)
		if args.silent == nil then args.silent = false end --Fallback
	end
	if type(args.forceSound) == "string" then
		args.forceSound = strToBool($)
		if args.forceSound == nil then args.forceSound = false end --Fallback
	end
	if type(args.instant) == "string" then
		args.instant = strToBool($)
		if args.instant == nil then args.instant = false end --Fallback
	end
	if type(args.pain) == "string" then
		args.pain = strToBool($)
		if args.pain == nil then args.pain = true end --Fallback
	end
	if type(args.loss) == "string" then
		args.loss = strToBool($)
		if args.loss == nil then args.loss = true end --Fallback
	end
	
	if args.division then
		--Potentially could kill the player; clamping will fix that.
		dmg = clamp(hellfire.maxHealth/$, 0, hellfire.maxHealth-1)
	else
		--You can't outright kill the player!
		dmg = clamp($, 0, hellfire.maxHealth-1)
	end

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if hf.canPlayerBeHurt(ply) then
			if args.pain then P_DoPlayerPain(ply) end

			if (not(hellfire.skinInfo.silentLoss) and not(args.silent)) or args.forceSound then S_StartSound(target, sfx_hfloss, ply) end

			if args.loss then
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
			end

			hellfire.health = clamp($-dmg, 1, hellfire.maxHealth)
			hellfire.transStuff.doFade = true
		end
	end
end
--Health ring progress remover function for mappers.
hf["directProgressWipe"] = function(ply)
	local hellfire = ply.hellfireHealth
	
	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		for i=#hellfire.rings,1,-1 do
			local ring = hellfire.rings[i]
			if ring.state == 0 and ring.fillAmt > 0 then
				ring.fillAmt = 0
				ring.doAnim = 0
			end
		end
		
		hellfire.transStuff.doFade = true
	end
end

--Healing function for mappers.
hf["directHeal"] = function(ply, heal, args)
	if heal == nil then heal = 1 end
	if args == nil then args = {} end
	if args.division == nil then args.division = false end
	if args.silent == nil then args.silent = false end
	if args.instant == nil then args.instant = false end

	local hellfire = ply.hellfireHealth

	--No overheal!
	if hellfire.health == hellfire.maxHealth then return end
	
	heal = tonumber($)
	if heal == nil then heal = 1 end
	if heal == 0 then return end --You aren't even healing any damage!
	if type(args.division) == "string" then
		args.division = strToBool($)
		if args.division == nil then args.division = false end --Fallback
	end
	if type(args.silent) == "string" then
		args.silent = strToBool($)
		if args.silent == nil then args.silent = false end --Fallback
	end
	if type(args.instant) == "string" then
		args.instant = strToBool($)
		if args.instant == nil then args.instant = false end --Fallback
	end

	if args.division then
		--Potentially could go over the max health; clamping will fix that.
		heal = clamp(hellfire.maxHealth/$, 1, hellfire.maxHealth)
	else
		--Ensures no overheal occurs.
		heal = clamp($, 1, hellfire.maxHealth)
	end
	
	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if not(args.silent) then S_StartSound(target, sfx_hfgain, ply) end
		
		hellfire.health = clamp($+heal, 1, hellfire.maxHealth)
		hellfire.transStuff.doFade = true
	end
end