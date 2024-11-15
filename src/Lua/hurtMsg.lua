--[[
A half-port of P_HitDeathMessages for any modes requiring it (since it never executes with HellfireHealth on).
This is only used in DamageMobj since KillMobj still executes normally.
This might become it's own standalone mod, since this is a issue with any mod that blocks normal damage code execution.
]]

rawset(_G, "hurtMessages", function(target, cause, src, dmgType)
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
end)