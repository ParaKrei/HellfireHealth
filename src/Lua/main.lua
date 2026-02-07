--[[
	The main file where the actual health system lives.
]]

--Initalize the table.
local function initHellfire(ply)
	if ply.hellfireHealth == nil then
		ply.hellfireHealth = {
			prefsLoaded = false,
			options = {
				disabled = false,
				allowOnSpecialStages = false,
				allowOnAllChars = false,
				doRingSpill = false,
				keepHealth = false,
				fillOnly = false,
				adminLock = false,
				doDeathJingle = true,
				skin = "red",
				meltRing = true,
				seeHealth = true,
				presetNum = 1,
				autoSave = true
			},
			notAllowed = false,
			bypassServerList = false,
			maxHealth = 5,
			fillCap = 5,
			health = 0,
			tookDmg = false,
			lastVals = {
				maxHealth = 0,
				fillCap = 0,
				health = 0,
				rings = {},
				lastRingCount = ply.rings
			},
			ringDeficit = 0,
			ringDefColor = V_YELLOWMAP,
			basePos = {x=-16, y=50},
			mainRing = {frame=0, isAnimating=false, animDone=false, lastTic=nil},
			healthPlate = {frame=0, isAnimating=false, animDone=false, lastTic=nil},
			rings = {},
			ringXOffset = 0,
			ringYOffset = ((16/2)+1),
			ringWrapAt = 8,
			ringWrapOffset = 0,
			ringWrapCount = 0,
			endWidth = 1,
			isDead = false,
			diedFromHealthLoss = false,
			transStuff = {
				overallAlpha = 1,
				isFadingHUD = false,
				doFade = false,
				lastTic = 0
			},
			lastSkin = "",
			skinInfo = {
				isBanned=false,
				shieldHack=false,
				deathOverride=false,
				noDeathJingle=false,
				silentLoss=false,
				serverBanned=false,
			},
			allowOverride = false,
			dmgOverride = false,
			deathOverride = false,
			healOverride = false,
			hudposGUI = {
				visible = false,
				lastInputTime = 0,
				lastGC = {},
				lastMButtons = {},
				lockedCamAngles = {angleturn=0, aiming=0},
				priority = 0,
				boundingBox = {x={0,0}, y={0,0}, scale={x=0,y=0}},
				dragging = false,
				grabPoint = {x=0, y=0},
				previewRingCount = 5,
				ogPresetNum = 0
			}
		}
	end
	local hellfire = ply.hellfireHealth

	--Fetch the client's preferences and apply.
	if hellfire.prefsLoaded == false then
		hf.loadPrefs(ply)
	end

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

	--Store the old values for keepHealth.
	hellfire.lastVals.maxHealth = hellfire.maxHealth
	hellfire.lastVals.fillCap = hellfire.fillCap
	hellfire.lastVals.health = hellfire.health
	hellfire.lastVals.rings = hellfire.rings

	--Fetch the cvars and set them.
	hellfire.maxHealth = CV_FindVar("hellfire_maxHealth").value
	hellfire.fillCap = CV_FindVar("hellfire_fillCap").value

	--Setup the health since it can't be done at define.
	hellfire.health = hellfire.maxHealth

	--Setup the rings.
	hf.resetRings(hellfire)

	--Restore the old values if using keepHealth (need to check if the old values are valid).
	if hellfire.options.keepHealth
	and (hellfire.lastVals.maxHealth > 0
	and hellfire.lastVals.fillCap > 0
	and hellfire.lastVals.health > 0
	and hellfire.lastVals.rings ~= {}) then
		if hellfire.lastVals.maxHealth ~= hellfire.maxHealth then
			--Calculate difference ratio from og values to apply to the new one.
			local ratio = FixedDiv(hellfire.lastVals.health*FU, hellfire.lastVals.maxHealth*FU)
			hellfire.health = FixedMul(hellfire.lastVals.maxHealth*FU, ratio)/FU
		else
			hellfire.health = hellfire.lastVals.health
		end
		
		hellfire.rings = hellfire.lastVals.rings
	end
end

local function killPlayer(hellfire, healthLoss, target, cause, src, dmgType)
	local ply = target.player

	hellfire.isDead = true
	hellfire.health = 0
	
	if healthLoss then
		hellfire.diedFromHealthLoss = true --Done to ensure nothing occurs twice.

		--Don't know why past me put in a P_DamageMobj call, as this is better.
		if ply.playerstate ~= PST_DEAD then
			P_KillMobj(target, cause, src, dmgType)
		end
	end

	--Stuff for the death jingle (Can't use in splitscreen, since the music doesn't come back when P2 dies; this is a bug with SRB2).
	if hellfire.options.doDeathJingle and not(hellfire.skinInfo.noDeathJingle) and not(splitscreen) then
		P_PlayJingleMusic(ply, "HFDTH", MUSIC_RELOADRESET, false, JT_OTHER)
		S_StartMusicCaption("\x8F\bDeath\x80", 3*TICRATE, ply)
	end
end

--Damage handler.
local function dmgHandler(target, cause, src, dmg, dmgType)
	if hf.objectExists(target) == false then return end --Non-valid checker
	if target.player.bot > 0 and CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.

	--Inject compatibility hooks, since adding them in afterwards won't let me override it.
	if hf.compat.MobjDamage ~= nil
		for _,func in pairs(hf.compat.MobjDamage) do
			func(target, cause, src, dmg, dmgType)
		end
	end

	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) and not(hellfire.dmgOverride) then
		--Stop Fang (and any others like him) from spamming the player to death.
		--Also put in checks for invuln, super, and strong guard.
		if hf.canPlayerBeHurt(ply) and not(hellfire.tookDmg) then
			hellfire.tookDmg = true
			--Remove/damage the shield if it exists instead (also some special exceptions for characters like the Mario Bros to get around their shield hack).
			if ply.powers[pw_shield] ~= SH_NONE and not(hellfire.skinInfo.shieldHack) then
				--Why did I try to recreate the shield damage code? This is SO much easier, smaller, and more reliable!
				return false
			else
				--Kill the player if they take damage with a health value of one.
				if hellfire.health == 1 then
					killPlayer(hellfire, true, target, cause, src, dmgType)
				else
					--Hurt code.
					P_DoPlayerPain(ply, src, cause)
					hurtMessages(target, cause, src, dmgType)
					P_ResetPlayer(ply) --Reset player call.

					--Play the health ring loss sfx.
					if not(hellfire.skinInfo.silentLoss) then
						S_StartSound(target, sfx_hfloss, ply)
					end
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
						hellfire.transStuff.doFade = true
					end
				end
			end
		else
			--Duplicate P_DoPlayerPain to replicate stock behavior better (Fang's cork gun doing knockback no matter what).
			P_DoPlayerPain(ply, src, cause)
			P_ResetPlayer(ply) --Reset player call.
		end

		--Stop the rest of the OG damage code.
		return true
	end

	ply.hellfireHealth.dmgOverride = false
end

--Little death handler for anything that instantly kills the player.
local function deathHandler(target, cause, src, dmgType)
	if hf.objectExists(target) == false then return end --Non-valid checker
	if target.player.bot > 0 and CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.

	--Inject compatibility hooks, since adding them in afterwards won't let me override it.
	if hf.compat.MobjDeath ~= nil
		for _,func in pairs(hf.compat.MobjDeath) do
			func(target, cause, src, dmg, dmgType)
		end
	end

	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) and not(hellfire.deathOverride) then
		--Setup the ring variables.
		local instaDeath = dmgType == DMG_INSTAKILL or dmgType == DMG_DEATHPIT or dmgType == DMG_CRUSHED or dmgType == DMG_DROWNED or dmgType == DMG_SPACEDROWN or dmgType == DMG_DEATHMASK

		if (instaDeath or hellfire.diedFromHealthLoss == false) and not(hellfire.skinInfo.deathOverride) then
			killPlayer(hellfire, false, target, cause, src, dmgType)
		end
		
		if hellfire.options.doDeathJingle and not(hellfire.skinInfo.noDeathJingle) and not(splitscreen) then
			ply.deadtimer = $-TICRATE --The death jingle is just short enough for this to work.
		end
	end

	ply.hellfireHealth.deathOverride = false
end

--Function to handle refilling health; can handle any ring collections that go above the fill cap in one tic (like ring monitors).
local function healthRefillHandler(ply, ringsAdded)
	local hellfire = ply.hellfireHealth

	local instaFill = ringsAdded >= hellfire.fillCap
	if hellfire.fillCap == 1 then instaFill = ringsAdded > 1 end --Special case for a fill cap of one.

	if not(ply.hellfireHealth.healOverride) then
		--If there is a ring deficit, put the collected rings towards it instead.
		if hellfire.options.doRingSpill and hellfire.ringDeficit > 0 then
			if not(instaFill) then
				hellfire.ringDeficit = hf.clamp($-ringsAdded, 0, FU)
				return
			else
				local leftOver = hf.clamp(hellfire.ringDeficit-ringsAdded, 0, FU)
				if ringsAdded > hellfire.ringDeficit then leftOver = hf.clamp(ringsAdded-hellfire.ringDeficit, 0, FU) end
				
				hellfire.ringDeficit = hf.clamp($-ringsAdded, 0, FU)
				
				if leftOver < hellfire.fillCap then instaFill = false end --Remove the instafill if there isn't enough left over.

				ringsAdded = leftOver --Set the ringsAdded to what's left over.
			end
		end

		if hellfire.options.fillOnly and not(instaFill) then return end --More rings than the fill cap per tic challenge.

		--Fetch the first empty ring.
		local targetRing = hf.getRingWithState(hellfire, 0, true)

		if hellfire.health < hellfire.maxHealth then --No overheal.
			if instaFill then --Handle any ring changes above the fill cap in a tic.
				hellfire.health = $+1
				S_StartSound(target, sfx_hfgain, ply) --Play the health ring gain sfx.
			else
				if targetRing.fillAmt < hellfire.fillCap-1 then --Any fillAmt below the cap will increase the fillAmt.
					targetRing.fillAmt = $+ringsAdded
					S_StartSound(target, sfx_hffill, ply) --Play the health ring fill sfx.
				else
					--When fillAmt hits the cap, give a new ring.
					hellfire.health = $+1
					S_StartSound(target, sfx_hfgain, ply) --Play the health ring gain sfx.
				end
			end
			hellfire.transStuff.doFade = true
		end
	end

	ply.hellfireHealth.healOverride = false
end

--The player think handler, misc. junk live here.
local function thkHandler(ply)
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	local hellfire = ply.hellfireHealth

	--Store the info on the current skin upon switch.
	if ply.mo.skin ~= hellfire.lastSkin then
		ply.hellfireHealth.skinInfo.isBanned = hf.getSkinVar(ply, "isBanned")
		ply.hellfireHealth.skinInfo.shieldHack = hf.getSkinVar(ply, "shieldHack")
		ply.hellfireHealth.skinInfo.deathOverride = hf.getSkinVar(ply, "deathOverride")
		ply.hellfireHealth.skinInfo.noDeathJingle = hf.getSkinVar(ply, "noDeathJingle")
		ply.hellfireHealth.skinInfo.silentLoss = hf.getSkinVar(ply, "silentLoss")
		ply.hellfireHealth.skinInfo.serverBanned = hf.getSkinVar(ply, "serverBanned")

		hellfire.allowOverride = false --Reset allow override
	end
	
	--Override for special cases.
	if not(hellfire.allowOverride) then
		--Check for any characters that mess with health OR fits the skin list.
		if ((hf.objectExists(ply.mo) and ply.mo.health ~= 1 and not(hellfire.isDead)) or hellfire.skinInfo.isBanned)
		and not(hellfire.options.allowOnAllChars)
		or (hellfire.skinInfo.serverBanned and not(hellfire.bypassServerList)) then
			if hellfire.notAllowed == false then
				hellfire.notAllowed = true
			end
		elseif G_IsSpecialStage() and not(hellfire.options.allowOnSpecialStages) then --Check if the current stage is a special stage.
			if hellfire.notAllowed == false then
				hellfire.notAllowed = true
			end
		elseif RingslingerRev ~= nil and RingslingerRev.GamemodeActive then --I'm not even going to allow the system to work when playing Ringslinger Revolution.
			if hellfire.notAllowed == false then
				hellfire.notAllowed = true
			end
		else
			if hellfire.notAllowed == true then
				hellfire.notAllowed = false
			end
		end
	end

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if hellfire.maxHealth > 1 then --Obviously, this code can only work if there is any health to refill, since the last ring can't.
			--This is where the refill handler is called, and ring difference is kept track.
			if ply.rings ~= hellfire.lastVals.lastRingCount then
				if ply.rings > hellfire.lastVals.lastRingCount then --ONLY on ring gain.
					healthRefillHandler(ply, (ply.rings-hellfire.lastVals.lastRingCount))
				end

				ply.hellfireHealth.lastVals.lastRingCount = ply.rings
			end
		end

		--Sometimes, too many rings get added every tick, thus breaking the refill handler.
		--Here, we just force a check for any ring that is at the fill cap.
		--Fetch the first empty ring.
		local targetRing = hf.getRingWithState(hellfire, 0, true)

		if targetRing ~= nil and targetRing.fillAmt > hellfire.fillCap-1 and targetRing.state ~= 1 then --This works so far... hard to test it, though.
			--When fillAmt hits the cap, give a new ring.
			hellfire.health = $+1
			S_StartSound(target, sfx_hfgain, ply) --Play the health ring gain sfx.
			hellfire.transStuff.doFade = true
		end
	end

	if hf.canPlayerBeHurt(ply) and hellfire.tookDmg then
		hellfire.tookDmg = false
	end

	ply.hellfireHealth.lastSkin = ply.mo.skin
end

local function ringSync(ply)
	local hellfire = ply.hellfireHealth
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.

	local count, gap = hf.countRingsWithState(hellfire, 1)

	if count ~= (hellfire.health-1) or gap then --Change/desync occured
		if gap then --PANIC!
			CONS_Printf(ply, "WARNING: A desync between your HUD and the data for your health has occured!")
			CONS_Printf(ply, "I will attempt to fix this issue immediately.")

			hf.resetRings(hellfire)

			for i=#hellfire.rings,1,-1 do
				local ring = hellfire.rings[i]
				local lastState = ring.state

				ring.state = 0
				ring.fillAmt = 0
				if lastState == 1 then ring.doAnim = 0 end

				local newCount, newGap = hf.countRingsWithState(hellfire, 1)

				if newCount == (hellfire.health-1) then break end
			end

			CONS_Printf(ply, "Please report this bug to the mod's GitHub page or discussions page with")
			CONS_Printf(ply, "what map you were on, what character you were playing,")
			CONS_Printf(ply, "and what mods you have loaded so we can work together to fix this issue!")
		end

		if count > (hellfire.health-1) then --Loss
			for i=#hellfire.rings,1,-1 do
				local ring = hellfire.rings[i]
				local lastState = ring.state

				ring.state = 0
				ring.fillAmt = 0
				if lastState == 1 then ring.doAnim = 0 end

				local newCount, newGap = hf.countRingsWithState(hellfire, 1)

				if newCount == (hellfire.health-1) then break end
			end
		elseif count < (hellfire.health-1) then --Gain
			for i=1,#hellfire.rings do
				local ring = hellfire.rings[i]
				local lastState = ring.state

				ring.state = 1
				ring.fillAmt = hellfire.fillCap
				if lastState == 0 then ring.doAnim = 1 end

				local newCount, newGap = hf.countRingsWithState(hellfire, 1)

				if newCount == (hellfire.health-1) then break end
			end
		end
	end
end

addHook("PlayerSpawn", initHellfire)
addHook("PlayerThink", thkHandler)
addHook("PlayerThink", ringSync)
addHook("MobjDamage", dmgHandler, MT_PLAYER)
addHook("MobjDeath", deathHandler, MT_PLAYER)

--Bot respawn fix--
addHook("PlayerThink", function(bot)
	if hf.objectExists(bot) ~= true and hf.objectExists(bot.mo) ~= true then return end --Non-valid checker
	if CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.
	if bot.bot == 0 then return end --Bots only

	local hellfire = bot.hellfireHealth

	if hellfire.health == 0 then --Bot died.
		if bot.playerstate == 0 then --Wait for when the bot respawns.
			initHellfire(bot)
		end
	end
end)