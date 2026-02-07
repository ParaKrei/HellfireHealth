--[[
	Compatibility stuff.
	Special behavior will go here.
]]

--[[Misc.]]--
--NiGHTS Special Stage Death Fix--
addHook("MobjDeath", function(target)
	if G_IsSpecialStage() and maptol & TOL_NIGHTS then --Only trigger for NiGHTS singleplayer stages, as the others don't softlock.
		local totalPlyCount = 0
		local deadPlyCount = 0
		local specCount = 0

		--Check every player for multiplayer compatibility.
		for ply in players.iterate() do
			if hf.objectExists(ply) then
				if (not(ply.spectator) and ply.playerstate == PST_DEAD) or (hf.objectExists(target) and hf.objectExists(target.player) and ply == target.player) then
					deadPlyCount = $+1 --Keeping count of dead players.
				elseif ply.spectator then
					specCount = $+1 --Keeping count of spectators
				end

				totalPlyCount = $+1 --Keeping count of total players.
			end
		end

		--Exit level when every (non-spectator) player is dead.
		if deadPlyCount == totalPlyCount-specCount then
			--Set EVERYONE's exiting timer to ~2 seconds.
			--I couldn't find a way to consistantly exit with just one player,
			--so everyone gets the timer.
			for ply in players.iterate() do
				ply.exiting = (2*TICRATE)+(TICRATE/2)+15
			end
		end
	end
end, MT_PLAYER)
--Metroid: Vanguard--
--Metroid stuff
--Metroid objID might be 2161
addHook("PlayerThink", function(ply)
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.hellfireHealth == nil then return end --Can't do anything yet...
	if ply.hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.

	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if ply.mo.metroidsnack then --AAAAAAAAAAAAAAAAAA
			--Find the attacker
			if hellfire.metroid == nil or not(hf.objectExists(hellfire.metroid)) then
				for mobj in mobjs.iterate() do
					if mobj.latchtarget ~= nil then
						if mobj.latchtarget == ply.mo then
							ply.hellfireHealth.metroid = mobj
							break
						end
					end
				end
			end

			if hellfire.metroid == nil then return --Must be dead.
			else
				if ply.rings == 0 then --Only do stuff if the player has no rings.
					local survival = hellfire.metroid.latchsuck
					if survival ~= nil then
						if survival <= 5 then --Your health system saved you from death!
							if hellfire.health > 1 then --Only do stuff if the player has MORE than 1 HP.
								hf.directDmg(ply, 1)
								hellfire.metroid = nil
							else
								hellfire.dmgOverride = true --Welp, you're dead.
								hellfire.metroid = nil
							end
						elseif survival <= 10 then --Little animation on the ring for feedback.
							if hellfire.health > 1 then --Only do stuff if the player has MORE than 1 HP.
								local curRing = hf.getRingWithState(ply.hellfireHealth, 1)
								if not(curRing.isAnimating) and curRing.doAnim ~= 2 and curRing.frame ~= 7 then curRing.doAnim = 2 end --Play the reverse shine animation ONLY once.
							end
						end
					end
				end
			end
		end
	end
end)
--Phazon support
addHook("PlayerThink", function(ply)
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.hellfireHealth == nil then return end --Can't do anything yet...
	if ply.hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.

	local hellfire = ply.hellfireHealth
	if hellfire.tookPhazonDmg == nil then hellfire.tookPhazonDmg = false end

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if ply.mo.pzpaintime and not(hellfire.tookPhazonDmg) then --I'M MELTING!
			if ply.rings == 0 and ply.powers[pw_shield] == SH_NONE then --Only do stuff if the player has no rings and no shield.
				if hellfire.health > 1 then --Only do stuff if the player has MORE than 1 HP.
					hf.directDmg(ply, 1)
					ply.mo.PhazonImmunity = true
					hellfire.tookPhazonDmg = true
					--Replicate effects
					P_StartQuake(12*FU, 2)
					S_StartSound(ply.mo, sfx_pzpain)
					P_SamFP(ply, PAL_NUKE, 8)
				else
					ply.mo.PhazonImmunity = false --Now you die.
				end
			end
		end

		if hf.canPlayerBeHurt(ply) then hellfire.tookPhazonDmg = false end
	end
end)

--[[Gamemodes]]--
--Battle--
--Stop damage when blocking.
hf.injectHook("MobjDamage", function(target, cause, src)
	if hf.objectExists(target) and hf.objectExists(target.player)
	and CBW_Battle ~= nil then
		if CBW_Battle.GuardTrigger(target, cause, src, dmg, dmgType) then
			target.player.hellfireHealth.dmgOverride = true
		end
	end
end, MT_PLAYER)

--ORANGE DEMON--
--Let the HP take the hit.
addHook("TouchSpecial", function(demon, victim)
	if CV_FindVar("hellfire_orangedemon").value == 0 then return end --Server disabled compatibility!
	
	if hf.objectExists(demon) and hf.objectExists(demon.player) then
		if demon.orangedemon ~= nil and not(demon.orangedemon.cured) then
			if (hf.objectExists(victim) and hf.objectExists(victim.player)) and not(victim.orangedemon) then
				local demonPly = demon.player
				local victimPly = victim.player
				local hellfire = victimPly.hellfireHealth

				if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
					if demon.orangedemon.delayTill < leveltime then
						if demonPly.powers[pw_flashing] or demon.state == S_PLAY_PAIN or demon.state == S_PLAY_DEAD then return end

						if hellfire.health > 1 or victimPly.powers[pw_shield] ~= SH_NONE then
							P_DamageMobj(demon, victim)
							P_DamageMobj(victim, demon)
						else
							P_KillMobj(victim, demon)
						end
					end
				end
			end
		end
		
		return true
	end
end, MT_PLAYER)
--Stop partner AI from picking up rings.
addHook("TouchSpecial", function(obj, target)
	if CV_FindVar("hellfire_orangedemon").value == 0 then return end --Server disabled compatibility!

	if hf.objectExists(target) and hf.objectExists(target.player) then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth
		
		if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			if hf.objectExists(obj) then
				if target.orangedemon ~= nil and not(target.orangedemon.cured) then
					return true
				end
			end
		end
	end
end, MT_RING)

--2011x--
--Let the HP take the hit.
if not(rawget(_G, "MT_SONICEXE")) then freeslot("MT_SONICEXE") end --I need the MOBJ type, so I'll attempt to use the method 2011x uses.
if not(rawget(_G, "S_EXERUN")) then freeslot("S_EXERUN") end --I need this state too.
if not(rawget(_G, "S_EXEFALL")) then freeslot("S_EXEFALL") end --I need this state too.
addHook("PlayerThink", function(ply)
	if activeexe == nil then return end --Can't do anything if 2011x doesn't exist!
	if ply.hellfireHealth == nil then return end --Can't do anything yet...
	if ply.hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.
	if CV_FindVar("hellfire_2011x").value == 0 then return end --Server disabled compatibility!

	--Setup variables for easy access.
	local X = activeexe
	local hellfire = ply.hellfireHealth
	if hellfire.X == nil then hellfire.X = {} end --Set up compat table.

	if X ~= 0 and hf.objectExists(X) and not(hellfire.notAllowed) then
		if X.target == ply.mo and X.gotcha then
			if not X.killplayer then --He's going to KILL me!
				if hellfire.health > 1 then --Only do stuff if the player has MORE than 1 HP.
					--Stop him from killing the player and damage the player's HP instead.
					hf.directDmg(ply, 1)

					P_DamageMobj(X, ply.mo, ply.mo) --B**CH-SLAP!
				end
			elseif X.killplayer <= 10 then --Little animation on the ring for feedback.
				if hellfire.health > 1 then --Only do stuff if the player has MORE than 1 HP.
					local curRing = hf.getRingWithState(ply.hellfireHealth, 1)
					if not(curRing.isAnimating) and curRing.doAnim ~= 2 and curRing.frame ~= 7 then curRing.doAnim = 2 end --Play the reverse shine animation ONLY once.
				end
			end
		end
	end
end)
--X doesn't care if you have invisibility when attacking you, if he can touch you, he WILL attack.
addHook("TouchSpecial", function(X, obj)
	if CV_FindVar("hellfire_2011x").value == 0 then return end --Server disabled compatibility!

	if (hf.objectExists(X) and X.health)
	and (hf.objectExists(obj) and hf.objectExists(obj.player) and obj.player.playerstate == PST_LIVE) then
		local ply = obj.player
		local hellfire = ply.hellfireHealth

		if obj ~= X.target then return true end --Don't do anything if that obj isn't X's target.

		if not(hellfire.notAllowed) and exerage then
			if X.state == S_EXERUN then
				if hellfire.health == 1 and ply.powers[pw_shield] == SH_NONE then --X will always grab you if you have no shield and have one health remaining.
					if ply.rings ~= 0 then
						hellfire.X.lastRings = ply.rings --Store the player's rings, as we'll get rid of them this tick, and restore it next tick.
						ply.rings = 0
					end
				else
					if not(X.melee) then X.melee = 1 end
				end
			else
				if hellfire.health == 1 and ply.powers[pw_shield] == SH_NONE and X.gotcha then
					if ply.rings == 0 and hellfire.X.lastRings ~= nil then
						ply.rings = hellfire.X.lastRings
						hellfire.lastRingCount = ply.rings
						hellfire.healOverride = true
					end
				end
			end
		end
	end
end, MT_SONICEXE)

--[[Characters]]--
--TAG TEAM (Silverhorn)--
--Transfer HP and lastRingCount between characters.
addHook("PreThinkFrame", function()
	if netgame or multiplayer then return end --TAGTEAM.lua cannot work on multiplayer since it's coded to check player 0 and 1.
	if players[0] == nil then return end --Can't do anything yet...
	if players[0].hellfireHealth == nil then return end --Can't do anything yet...
	if CV_FindVar("hellfire_botEnable").value == 0 then return end --This won't do anything if the bot doesn't use the system!
	if players[0].hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.

	--Make sure that the bot exists, and ensure that only the Silverhorn characters can use it.
	if hf.objectExists(players[1]) and (players[0].mo.skin == "aether" or players[0].mo.skin == "inazuma") and (players[1].mo.skin == "aether" or players[1].mo.skin == "inazuma") then
		local p1 = players[0]
		local p2 = players[1]
		local mo1 = p1.mo
		local mo2 = p2.mo

		local p1hf = p1.hellfireHealth
		local p2hf = p2.hellfireHealth

		if p1hf.tagTeam == nil then
			p1hf.tagTeam = {["lastSkin"]=""}
		end
		if p2hf.tagTeam == nil then
			p2hf.tagTeam = {["lastSkin"]=""}
		end

		if p1.silverhornswapping and players[0].mo.skin ~= p1hf.tagTeam.lastSkin then
			if (p1hf.tagTeam.lastSkin == "aether" and players[0].mo.skin == "inazuma")
			or (p1hf.tagTeam.lastSkin == "inazuma" and players[0].mo.skin == "aether") then
				p1hf.healOverride = true
				p2hf.healOverride = true
				
				p1hf.lastRingCount = p2.rings
				p2hf.lastRingCount = p1.rings

				p1.hellfireHealth = p2hf
				p2.hellfireHealth = p1hf
			end
		end

		p1hf.tagTeam.lastSkin = players[0].mo.skin
		p2hf.tagTeam.lastSkin = players[1].mo.skin
	end
end)

--Echoes & Abyss (StephChars v4)--
--HP first, then Abyss.
--Fake DamageMobj to avoid triggering Abyss.
addHook("ShouldDamage", function(target, cause, src, dmg, dmgType)
	if hf.objectExists(target) and hf.objectExists(target.player)
	and target.skin == "echoes"
	and not (target.player.powers[pw_carry] == CR_NIGHTSMODE
	or target.player.powers[pw_carry] == CR_NIGHTSFALL) then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth
		local echoes = ply.echoes

		if echoes ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			if not(hf.canPlayerBeHurt(ply)) then return end --Bypass if player can't be hurt.
			if ply.spectator then return end --Bypass for spectators.
			if ply.pflags & PF_GODMODE then return end --Bypass for GODMODE.
			if dmgType & DMG_DEATHMASK then return end --Bypass for DEATHMASK.

			if hellfire.health > 1 then
				if (hf.objectExists(echoes.voidorb) or echoes.twirltimer > 0)
				and echoes.stuncooldown <= 0 then
					if not(hellfire.echoes.sndPlayed) then
						P_DoPlayerPain(ply)
						Echoes.PainSound(target)
						echoes.stuncooldown = 8*TICRATE
						hellfire.echoes.sndPlayed = true
					end
				else
					if not(hellfire.echoes.sndPlayed) then
						hf.directDmg(ply, 1, {forceSound=true})
						Echoes.PainSound(target)
						hellfire.echoes.sndPlayed = true
					end
				end

				return false
			else
				hellfire.dmgOverride = true
			end
		end
	end
end, MT_PLAYER)
addHook("PlayerThink", function(ply)
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.hellfireHealth == nil then return end --Can't do anything yet...
	if ply.hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.
	if ply.mo.skin ~= "echoes" then return end --ONLY for this skin.

	local hellfire = ply.hellfireHealth

	if ply.echoes ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if hellfire.echoes == nil then hellfire.echoes = {} end

		if hf.canPlayerBeHurt(ply) and hellfire.echoes.sndPlayed then
			hellfire.echoes.sndPlayed = false
		end
	end
end)
--Old implementation.
-- hf.injectHook("MobjDamage", function(target, cause, src)
-- 	if hf.objectExists(target) and hf.objectExists(target.player)
-- 	and target.skin == "echoes"
-- 	and not (target.player.powers[pw_carry] == CR_NIGHTSMODE
-- 	or target.player.powers[pw_carry] == CR_NIGHTSFALL) then
-- 		--Setup variables for easy access.
-- 		local ply = target.player
-- 		local hellfire = ply.hellfireHealth
-- 		local echoes = ply.echoes

-- 		if echoes ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
-- 			if (hf.objectExists(echoes.voidorb) or echoes.twirltimer > 0)
-- 			and echoes.stuncooldown <= 0 then
-- 				hellfire.dmgOverride = true
-- 			else
-- 				if echoes.abyssactive > 1 then --Should catch Force shield implementation, along with any others that increase "abyssactive" above 1.
-- 					hellfire.dmgOverride = true
-- 				else
-- 					if hellfire.health > 1 then
-- 						echoes.abyssactive = $+1
-- 					elseif echoes.abyssactive > 0 then
-- 						hellfire.dmgOverride = true
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end)

--Mario & Luigi (MarioBros)--
--Working around their health system without losing their unique pain states was too much of a headache, so I'm just not doing it.
--Besides, their health system is already extremely similar to what mine does, just with less customizability.
addHook("PlayerThink", function(ply)
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.hellfireHealth == nil then return end --Can't do anything yet...
	if ply.hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.
	if ply.mo.skin ~= "mario" and ply.mo.skin ~= "luigi" then return end --ONLY for these skins.
	
	local hellfire = ply.hellfireHealth
	
	if not(hellfire.notAllowed) then
		hellfire.allowOverride = true
		hellfire.notAllowed = true

		CONS_Printf(ply, "\x85\bHellfire Health and the Mario Bros. just fundamentally conflict too much. I couldn't find a way to make it work, so it won't.")
		CONS_Printf(ply, "\x85\bPlaying Ultimate mode, or running through the game as Tiny Mario/Luigi makes all damage insta-kill, so there's that if you want a challenge.")
	end
end)

--Mario & Luigi (N64MarioBros)--
--The health system is too complex to work around, plus the health system of the character can be disabled.
--Warning and disabling Hellfire Health on any players playing as the N64 Mario Bros.
addHook("PlayerThink", function(ply)
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.hellfireHealth == nil then return end --Can't do anything yet...
	if ply.hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.
	if ply.mo.skin ~= "n64mario" and ply.mo.skin ~= "n64luigi" and ply.mo.skin ~= "sgimario" then return end --ONLY for these skins.
	
	local hellfire = ply.hellfireHealth
	
	if CV_FindVar("n64power").value == 1 then
		if not(hellfire.notAllowed) then
			hellfire.allowOverride = true
			hellfire.notAllowed = true

			CONS_Printf(ply, "\x85\bHellfire Health will NOT function with the N64 Mario Bros as long as \"n64power\" is enabled!")
		end
	else
		hellfire.allowOverride = false
	end
end)

--Doomguy--
--Since I can't do the other way, Hellfire Health first, then OG health system.
hf.injectHook("MobjDamage", function(target, cause, src)
	if hf.objectExists(target) and hf.objectExists(target.player)
	and target.skin == "doomguy"
	and not (target.player.powers[pw_carry] == CR_NIGHTSMODE
	or target.player.powers[pw_carry] == CR_NIGHTSFALL) then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth
		local doom = ply.doomguy

		if doom ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			if hellfire.health > 1 then
				doom.invulnerability_tick = 1
			else
				hellfire.dmgOverride = true
				hellfire.deathOverride = true
			end
		end
	end
end, MT_PLAYER)
--Properly do death stuff.
hf.injectHook("MobjDeath", function(target, cause, src)
	if hf.objectExists(target) and hf.objectExists(target.player)
	and target.skin == "doomguy"
	and not (target.player.powers[pw_carry] == CR_NIGHTSMODE
	or target.player.powers[pw_carry] == CR_NIGHTSFALL) then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth
		local doom = ply.doomguy

		if doom ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			hellfire.isDead = true
			hellfire.health = 0

			--Stuff for the death jingle (Can't use in splitscreen, since the music doesn't come back when P2 dies; this is a bug with SRB2).
			if hellfire.options.doDeathJingle and not(hellfire.skinInfo.noDeathJingle) and not(splitscreen) then
				P_PlayJingleMusic(ply, "HFDTH", MUSIC_RELOADRESET, false, JT_OTHER)
				S_StartMusicCaption("\x8F\bDeath\x80", 3*TICRATE, ply)
			end
		end
	end
end, MT_PLAYER)

--Samus--
--Yeah, to be honest, I have no idea on what to do with Samus, so no Hellfire Health for her.
addHook("PlayerThink", function(ply)
	if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.hellfireHealth == nil then return end --Can't do anything yet...
	if ply.hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.
	if ply.mo.skin ~= "basesamus" and ply.mo.skin ~= "samus" then return end --ONLY for these skins.
	
	local hellfire = ply.hellfireHealth
	
	if not(hellfire.notAllowed) then
		hellfire.allowOverride = true
		hellfire.notAllowed = true

		CONS_Printf(ply, "\x85\bHellfire Health (kinda) breaks Samus, plus she already has a robust health system. If you want a challenge, use Hyper Mode!")
	end
end)

--Takis--
--Hellfire Health first, then OG health system.
hf.injectHook("MobjDamage", function(target, cause, src)
	if hf.objectExists(target) and hf.objectExists(target.player)
	and target.skin == "takisthefox"
	and not (target.player.powers[pw_carry] == CR_NIGHTSMODE
	or target.player.powers[pw_carry] == CR_NIGHTSFALL) then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth
		local takis = ply.takistable

		if takis ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			if hellfire.health > 1 then
				target.player.powers[pw_shield] = SH_PITY
				hf.directDmg(ply, 1)
			else
				hf.directProgressWipe(ply)
				hellfire.dmgOverride = true
				hellfire.deathOverride = true
			end
		end
	end
end, MT_PLAYER)
--Properly do death stuff.
hf.injectHook("MobjDeath", function(target, cause, src)
	if hf.objectExists(target) and hf.objectExists(target.player)
	and target.skin == "takisthefox"
	and not (target.player.powers[pw_carry] == CR_NIGHTSMODE
	or target.player.powers[pw_carry] == CR_NIGHTSFALL) then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth
		local takis = ply.takistable

		if takis ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			hellfire.isDead = true
			hellfire.health = 0

			--Stuff for the death jingle (Can't use in splitscreen, since the music doesn't come back when P2 dies; this is a bug with SRB2).
			if hellfire.options.doDeathJingle and not(hellfire.skinInfo.noDeathJingle) and not(splitscreen) then
				P_PlayJingleMusic(ply, "HFDTH", MUSIC_RELOADRESET, false, JT_OTHER)
				S_StartMusicCaption("\x8F\bDeath\x80", 3*TICRATE, ply)
			end
		end
	end
end, MT_PLAYER)
--Pit handler; transfer damage to Hellfire Health.
addHook("PostThinkFrame", function()
	for ply in players.iterate() do
		if not(hf.objectExists(ply)) or not(hf.objectExists(ply.mo)) then continue end --Player and/or it's mobj doesn't exist!
		if ply.hellfireHealth == nil then continue end --Can't do anything yet...
		if ply.hellfireHealth.options.disabled then continue end --Don't do ANYTHING if the player doesn't want the system.
		if ply.mo.skin ~= "takisthefox" then continue end --ONLY for this skins.
		
		--Setup variables for easy access.
		local hellfire = ply.hellfireHealth
		local takis = ply.takistable

		if takis ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			if takis.pitanim == TICRATE then
				if hellfire.health > 1 then
					takis.heartcards = $+1
					hf.directDmg(ply, 1, {loss=false})
				else
					hf.directProgressWipe(ply)
					hellfire.dmgOverride = true
					hellfire.deathOverride = true
				end
			end
		end
	end
end)