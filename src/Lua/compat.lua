--[[
Compatibility stuff.
Special behavior will go here.
]]

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