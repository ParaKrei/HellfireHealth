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
			--Battle override (for players)!
			if cause ~= nil and cause.valid and cause.player ~= nil and cause.player.battle_hurttxt then
				if CBW_Battle ~= nil then
					local message = cause.player.battle_hurttxt
					print(CBW_Battle.CustomHurtMessage(ply, cause, message))
					return
				end
			end

			local targetName = ply.name
			local srcName = ""
			if src ~= nil and src.valid then
				if src.player ~= nil then
					srcName = src.player.name
				else
					if src.name ~= nil then
						srcName = src.name
					elseif src.info.name ~= nil then
						srcName = src.info.name
					else
						srcName = "Something"
					end
				end
			end

			--Battle override (non-players)!
			if cause ~= nil and cause.valid and cause.type ~= MT_PLAYER then
				if CBW_Battle ~= nil then
					local name = ""
					if cause.name ~= nil then name = cause.name
					elseif cause.info.name ~= nil then name = cause.info.name
					else name = "Something" end

					print(CBW_Battle.CustomHurtMessage(ply, src, name))
					return
				end
			end

			if src.player ~= nil and src.player.state == PST_DEAD then
				srcName = "The late "+srcName
			elseif src.health <= 0 then
				srcName = "The late "+srcName
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