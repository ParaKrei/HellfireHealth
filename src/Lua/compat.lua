--[[
Compatibility stuff.
Special behavior will go here.
]]

--NiGHTS Special Stage Death Fix--
addHook("MobjDeath", function(target)
	if G_IsSpecialStage() and maptol & TOL_NIGHTS then --Only trigger for NiGHTS singleplayer stages, as the others don't softlock.
		local totalPlyCount = 0
		local deadPlyCount = 0
		local specCount = 0

		--Check every player for multiplayer compatibility.
		for ply in players.iterate() do
			if objectExists(ply) then
				if (not(ply.spectator) and ply.playerstate == PST_DEAD) or (objectExists(target) and objectExists(target.player) and ply == target.player) then
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
				ply.exiting = (2*TICRATE)+3
			end
		end
	end
end, MT_PLAYER)

--ORANGE DEMON--
--Target HP instead.
addHook("TouchSpecial", function(obj, target)
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if objectExists(obj) then
			if obj.orangedemon ~= nil and not(obj.orangedemon.cured) then
				if objectExists(target) and ply and not(target.orangedemon) then
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
--Stop partner AI from picking up rings.
addHook("TouchSpecial", function(obj, target)
	--Setup variables for easy access.
	local ply = target.player
	local hellfire = ply.hellfireHealth

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		if objectExists(obj) then
			if target.orangedemon ~= nil and not(target.orangedemon.cured) then
				return true
			end
		end
	end
end, MT_RING)

--TAG TEAM (Silverhorn)--
addHook("PreThinkFrame", function()
	if netgame or multiplayer then return end --TAGTEAM.lua cannot work on multiplayer since it's coded to check player 0 and 1.
	if players[0] == nil then return end --Can't do anything yet...
	if players[0].hellfireHealth == nil then return end --Can't do anything yet...
	if CV_FindVar("hellfire_botEnable").value == 0 then return end --This won't do anything if the bot doesn't use the system!
	if players[0].hellfireHealth.options.disabled then return end --Don't do ANYTHING if the player doesn't want the system.

	--Make sure that the bot exists.
	if objectExists(players[1]) then
		local p1 = players[0]
		local p2 = players[1]
		local mo1 = p1.mo
		local mo2 = p2.mo

		if p1.silverhornswapping then
			local lastRings = p1.hellfireHealth.lastRingCount
			local p1hf = p1.hellfireHealth
			local p2hf = p2.hellfireHealth

			p2hf.lastRingCount = lastRings

			p1.hellfireHealth = p2hf
			p2.hellfireHealth = p1hf
		end
	end
end)

--Echoes & Abyss (StephChars v4)--
addHook("MobjDamage", function(target, cause, src)
	if objectExists(target) and objectExists(target.player)
	and target.skin == "echoes"
	and not (target.player.powers[pw_carry] == CR_NIGHTSMODE or 
	target.player.powers[pw_carry] == CR_NIGHTSFALL) then
		--Setup variables for easy access.
		local ply = target.player
		local hellfire = ply.hellfireHealth
		local echoes = ply.echoes

		if echoes ~= nil and hellfire ~= nil and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
			if (objectExists(echoes.voidorb) or echoes.twirltimer > 0)
			and echoes.stuncooldown <= 0 then
				hellfire.dmgOverride = true
			else
				if echoes.abyssactive > 1 then
					hellfire.dmgOverride = true
				else
					if hellfire.health > 1 then
						if echoes.abyssactive == 0 then
							echoes.abyssactive = 1
						else
							echoes.abyssactive = 2
						end
					else
						if echoes.abyssactive > 0 then
							hellfire.dmgOverride = true
						end
					end
				end
			end
		end
	end
end)