--[[
	The floating in-world health bar's code lives here.
]]

--Bar spawner--
addHook("PlayerSpawn", function(ply)	
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
end)

--Bot respawn fix--
addHook("PlayerThink", function(bot)
	if hf.objectExists(bot) ~= true and hf.objectExists(bot.mo) ~= true then return end --Non-valid checker
	if CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.
	if bot.bot == 0 then return end --Bots only

	local hellfire = bot.hellfireHealth

	if hf.getPlayerBar(bot) == nil then --Bot doesn't have a bar!
		if bot.playerstate == 0 then --Only give the bot a bar if it's alive.
			local bar = P_SpawnMobjFromMobj(bot.mo, 0, 0, P_GetPlayerHeight(bot), MT_HFBAR)
			bar.target = bot.mo
			bar.clones = {}
			
			for i=0,49 do
				local clone = P_SpawnMobjFromMobj(bar, 25*FU, 25*FU, 0, MT_HFBAR)

				table.insert(bar.clones, clone)
			end

			table.insert(hf.bars, bar)
		end
	end
end)

--Remove a player's bars if they leave--
addHook("PlayerQuit", function(ply)
	hf.removePlyBars(ply)
end)

--Little function to quickly set a bar's visuals--
local function setBarFrame(bar, i, hellfire)
	--Make the bars match the ring states.
	if hellfire.rings[i].state == 1 then
		bar.frame = 5
	elseif hellfire.rings[i].state == 0 then
		--Use the fillAmt for the animation frames; coded to be modular with different fillCaps.
		if hellfire.fillCap ~= 5 then
			local newFrame = hellfire.rings[i].fillAmt/hf.clamp((hellfire.fillCap/5), 1, FU)
			bar.frame = newFrame
		else
			bar.frame = hellfire.rings[i].fillAmt
		end
	end
end

--Main thinking hook for bars (positioning, rendering, etc)--
addHook("MobjThinker", function(mobj)
	if hf.objectExists(mobj.target) and hf.objectExists(mobj.target.player) then
		if mobj.target.player == displayplayer
		or mobj.target.player == secondarydisplayplayer then --Splitscreen support
			if not(mobj.flags2 & MF2_DONTDRAW) then
				mobj.flags2 = $|MF2_DONTDRAW
				for _,clone in ipairs(mobj.clones) do
					clone.flags2 = $|MF2_DONTDRAW
				end
			end

			return
		end
		
		local ply = mobj.target.player
		local hellfire = ply.hellfireHealth

		local disableRender = false
		if (hf.objectExists(displayplayer) and displayplayer.hellfireHealth.options.seeHealth == false)
		or (hellfire.options.disabled or hellfire.notAllowed) or (ply.bot > 0 and CV_FindVar("hellfire_botEnable").value == 0) then
			disableRender = true
		end

		local barSprite = SPR_HRHB
		if hf.objectExists(displayplayer)
		and displayplayer.hellfireHealth.options.skin == "yellow" then
			barSprite = SPR_HYHB
		end

		local xscale = 1
		local offset = 1
		if not(disableRender) then
			xscale = hf.clamp(hellfire.maxHealth-5, 1, 10)
			offset = ((25*hellfire.maxHealth)/2)+(hellfire.maxHealth/2)

			mobj.sprite = barSprite
			mobj.scale = FU/2
			mobj.spritexscale = FU/xscale
			mobj.spriteyscale = FU/2
			mobj.spritexoffset = offset*FU
			mobj.flags2 = $&~MF2_DONTDRAW

			if hellfire.health == 0 then
				mobj.frame = 0
			else
				mobj.frame = 5
			end
		else
			mobj.flags2 = $|MF2_DONTDRAW
		end

		hf.moveMobj(mobj, ply.mo.x, ply.mo.y, (ply.mo.z+ply.mo.height)+(20*FU))

		for i,clone in ipairs(mobj.clones) do
			if not(disableRender) then
				clone.sprite = barSprite
				clone.scale = FU/2
				clone.spritexscale = FU/xscale
				clone.spriteyscale = FU/2
				clone.spritexoffset = ((offset-i)-(25*i))*FU

				if i >= hellfire.maxHealth then
					clone.flags2 = $|MF2_DONTDRAW
				else
					clone.flags2 = $&~MF2_DONTDRAW
				end
				
				if i < hellfire.maxHealth then
					setBarFrame(clone, i, hellfire)
				end
			else
				clone.flags2 = $|MF2_DONTDRAW
			end

			hf.moveMobj(clone, mobj.x, mobj.y, mobj.z)
		end
	end
end, MT_HFBAR)

--Little ThinkFrame hook to remove any broken bars--
addHook("ThinkFrame", function()
	for i,bar in ipairs(hf.bars) do
		--Remove entry if the bar no longer exists.
		if not(hf.objectExists(bar)) then
			table.remove(hf.bars, i)
		end
		--Remove bars if the target is dead.
		if hf.objectExists(bar) and hf.objectExists(bar.target) and hf.objectExists(bar.target.player) and bar.target.player.playerstate == PST_DEAD then
			for i,clone in ipairs(bar.clones) do P_RemoveMobj(clone) end
			P_RemoveMobj(bar)
			table.remove(hf.bars, i)
		end
		--Remove bars if the target no longer exists.
		if hf.objectExists(bar) and (not(hf.objectExists(bar.target)) or not(hf.objectExists(bar.target.player))) then
			for i,clone in ipairs(bar.clones) do P_RemoveMobj(clone) end
			P_RemoveMobj(bar)
			table.remove(hf.bars, i)
		end
	end
end)