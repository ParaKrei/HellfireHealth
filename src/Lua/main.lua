--[[
The main file where the actual health system lives.
]]

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
				skin = "red",
				seeHealth = true,
				autoSave = true
			},
			notAllowed = false,
			bypassServerList = false,
			maxHealth = 5,
			fillCap = 5,
			health = 0,
			lastRingCount = ply.rings,
			ringDeficit = 0,
			ringDefColor = V_YELLOWMAP,
			curRing = 0,
			basePos = {x=hudinfo[HUD_RINGS].x-1, y=hudinfo[HUD_RINGS].y+15}, --Get the position of the og "RINGS" HUD element and position off of that.
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
			},
			lastSkin = "",
			skinInfo = {
				isBanned=false,
				shieldHack=false,
				deathOverride=false
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

	--Move the HUD to the position of the score text if BattleMod is loaded.
	if CBW_Battle ~= nil then
		hellfire.basePos.y = hudinfo[HUD_RINGS].y+34
	end

	--Fetch the cvars and set them.
	hellfire.maxHealth = CV_FindVar("hellfire_maxHealth").value
	hellfire.fillCap = CV_FindVar("hellfire_fillCap").value

	--Setup the health and curRing since it can't be done at define.
	hellfire.health = hellfire.maxHealth
	hellfire.curRing = hellfire.maxHealth-1

	--Fetch the client's preferences and apply.
	loadPrefs(ply)

	--Setup the rings.
	resetRings(hellfire)
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
	if objectExists(target) == false then return end --Non-valid checker
	if target.player.bot > 0 and CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.

	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	--Battle Overrides
	if CBW_Battle ~= nil then
		local battle = CBW_Battle

		if battle.GuardTrigger(target, cause, src, dmg, dmgType) then
			return true
		end
	end

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		--Setup the ring variables.
		local targetRing = hellfire.rings[hellfire.curRing]
		local ringAhead = hellfire.rings[hellfire.curRing+1]

		--Stop Fang (and any others like him) from spamming the player to death.
		if ply.powers[pw_flashing] <= 0 then
			--Remove/damage the shield if it exists instead (also some special exceptions for characters like the Mario Bros to get around their shield hack).
			if ply.powers[pw_shield] ~= SH_NONE and not(hellfire.skinInfo.shieldHack) then
				P_RemoveShield(ply) --Damage the shield.
				P_PlayDeathSound(target, ply) --Play the normal damage sound.
				P_DoPlayerPain(ply, src, cause)
			else
				--Kill the player if they take damage with a health value of one.
				if hellfire.health == 1 then
					killPlayer(hellfire, true, target, cause, src)
				else
					--Hurt code.
					P_DoPlayerPain(ply, src, cause)
					hurtMessages(target, cause, src, dmgType)

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
		else
			--Duplicate P_DoPlayerPain to replicate stock behavior better (Fang's cork gun doing knockback no matter what).
			P_DoPlayerPain(ply, src, cause)
		end

		--Stop the rest of the OG damage code.
		return true
	end
end

--Little death handler for anything that instantly kills the player.
local function deathHandler(target, cause, src, dmgType)
	if objectExists(target) == false then return end --Non-valid checker
	if target.player.bot > 0 and CV_FindVar("hellfire_botEnable").value == 0 then return end --Don't execute for bots if not allowed.

	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		--Setup the ring variables.
		local targetRing = hellfire.rings[hellfire.curRing]
		local ringAhead = hellfire.rings[hellfire.curRing+1]
		local instaDeath = dmgType == DMG_INSTAKILL or dmgType == DMG_DEATHPIT or dmgType == DMG_CRUSHED or dmgType == DMG_DROWNED or dmgType == DMG_SPACEDROWN or dmgType == DMG_DEATHMASK

		if (instaDeath or hellfire.diedFromHealthLoss == false) and not(hellfire.skinInfo.deathOverride) then
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

--The player think handler, misc. junk live here.
local function thkHandler(ply)
	local hellfire = ply.hellfireHealth
	if objectExists(ply.mo) ~= true then return end --Don't do anything if the player mobj doesn't exist.

	--Store the info on the current skin upon switch.
	if ply.mo.skin ~= hellfire.lastSkin then
		ply.hellfireHealth.skinInfo.isBanned = isBannedSkin(ply)
		ply.hellfireHealth.skinInfo.shieldHack = isShieldHackSkin(ply)
		ply.hellfireHealth.skinInfo.deathOverride = isSpecialDeathSkin(ply)
	end
	
	--Check for any characters that mess with health OR fits the skin list.
	if ((objectExists(ply.mo) and ply.mo.health ~= 1 and not(hellfire.isDead)) or hellfire.skinInfo.isBanned) and not(hellfire.options.allowOnAllChars) then
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

	ply.hellfireHealth.lastSkin = ply.mo.skin
end

addHook("PlayerSpawn", initHellfire)
addHook("PlayerThink", thkHandler)
addHook("MobjDamage", dmgHandler, MT_PLAYER)
addHook("MobjDeath", deathHandler, MT_PLAYER)