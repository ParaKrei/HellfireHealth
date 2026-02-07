--[[
	HUD handler, plus the unique GUI for setting the HUD position, since this file is small.
]]

--This is where the HUD is drawn.
local function hudHandler(hudDrawer, ply, displayType)
	if displayType == nil then displayType = 0 end
	
	local hellfire = ply.hellfireHealth
	local gui = hellfire.hudposGUI
	if hf.objectExists(ply.mo) == false then return end --Don't draw anything if the player mobj doesn't exist.
	if LugentMenu ~= nil and LugentMenu.Active then return end --Don't draw anything if the menu is open.

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		local graphicPrefix = ""
		local ringType = ""
		if hellfire.options.skin == "red" then
			graphicPrefix = "HR"
		elseif hellfire.options.skin == "yellow" then
			graphicPrefix = "HY"
		end
		if hellfire.options.meltRing then
			ringType = "MR"
		else
			ringType = "SR"
		end

		--Alpha stuff (for fading in/out the HUD).
		local hudTrans = 0
		if hellfire.isDead then
			if hellfire.transStuff.isFadingHUD == false then
				hellfire.transStuff.isFadingHUD = true
				hellfire.transStuff.overallAlpha = 5
			end
			if ply.jointime % 2 == 0 then
				if hellfire.transStuff.overallAlpha >= 1 then
					hellfire.transStuff.overallAlpha = $-1
				end
			end
		elseif ply.exiting then
			if hellfire.transStuff.isFadingHUD == false then
				hellfire.transStuff.isFadingHUD = true
				hellfire.transStuff.overallAlpha = 5
			end

			if ply.jointime % 2 == 0 then
				if hellfire.transStuff.overallAlpha < 10 then
					hellfire.transStuff.overallAlpha = $+1
				end
			end
		elseif hellfire.transStuff.doFade then
			if hellfire.transStuff.isFadingHUD == false then
				hellfire.transStuff.isFadingHUD = true
				hellfire.transStuff.overallAlpha = 5
			end
			if ply.jointime % 1 == 0 then
				if hellfire.transStuff.overallAlpha >= 1 then
					hellfire.transStuff.overallAlpha = $-1
				else
					hellfire.transStuff.doFade = false
					hellfire.transStuff.lastTic = ply.jointime
				end
			end
		else
			if hellfire.transStuff.overallAlpha < 5 and hellfire.transStuff.isFadingHUD then
				if ply.jointime >= hellfire.transStuff.lastTic+(TICRATE*2) then
					if ply.jointime % 1 == 0 then
						if hellfire.transStuff.overallAlpha <= 5 then
							hellfire.transStuff.overallAlpha = $+1
						else
							hellfire.transStuff.isFadingHUD = false
						end
					end
				end
			end
		end

		if hellfire.transStuff.isFadingHUD then
			hudTrans = hellfire.transStuff.overallAlpha<<V_ALPHASHIFT
			if hellfire.transStuff.overallAlpha == 10 or hellfire.transStuff.overallAlpha == 1 then
				hudTrans = V_HUDTRANS
			end
		else
			if gui.visible then hudTrans = 0 else hudTrans = V_HUDTRANSHALF end
			hellfire.transStuff.overallAlpha = 1
		end

		--Stop drawing stuff once the alpha hits the max value.
		if hellfire.transStuff.overallAlpha < 10 then
			local basePos = hellfire.basePos
			local patches = {
				healthPlate = hudDrawer.getSpritePatch(graphicPrefix.."HP", hellfire.healthPlate.frame),
				mainRing = hudDrawer.getSpritePatch(graphicPrefix..ringType, hellfire.mainRing.frame),
				pixel = hudDrawer.getSpritePatch("HFPX", 15),
				endCap = hudDrawer.getSpritePatch("HFPE")
			}

			--Death animation for the base-plate.
			if hellfire.health == 0 and hellfire.healthPlate.animDone == false then
				hf.animateObj(hellfire.healthPlate, ply.jointime, {ticsPerFrame=1, frames={1,6}}, function() hellfire.healthPlate.animDone=true end)
			end

			local middle = (hellfire.ringYOffset*hellfire.ringWrapCount)/2
			local hpHead = {
				patch = patches.healthPlate,
				flags = V_PERPLAYER|hudTrans,
				x = (basePos.x)*FU,
				y = (basePos.y+middle)*FU,
				scale = FU/2
			}
			hf.dataDraw(hudDrawer, "scaled", hpHead)

			local backdrop1 = {
				patch = patches.pixel,
				colormap = hudDrawer.getColormap(nil, SKINCOLOR_BLACK),
				flags = V_PERPLAYER|hudTrans,
				x = (basePos.x+(patches.healthPlate.width/2))*FU,
				y = basePos.y*FU,
				scale = {
					x = 22*FU,
					y = ((hellfire.ringYOffset*hellfire.ringWrapCount)*FU)+FixedDiv(175,10)
				}
			}
			hf.dataDraw(hudDrawer, "stretched", backdrop1) --drawFill doesn't have enough options, and it's integer only... so this is my best option.

			local ringsWidth = hf.clamp((patches.mainRing.width/4)*#hellfire.rings, 0, FU)
			if #hellfire.rings >= hellfire.ringWrapAt then
				ringsWidth = hf.clamp((patches.mainRing.width/4)*(hellfire.ringWrapAt-1), 0, FU)
			end

			local backdrop2 = {
				patch = patches.pixel,
				colormap = hudDrawer.getColormap(nil, SKINCOLOR_BLACK),
				flags = V_PERPLAYER|hudTrans,
				x = backdrop1.x+backdrop1.scale.x,
				y = basePos.y*FU,
				scale = {
					x = ringsWidth*FU,
					y = backdrop1.scale.y
				}
			}
			hf.dataDraw(hudDrawer, "stretched", backdrop2) --drawFill doesn't have enough options, and it's integer only... so this is my best option.

			local hpEnd = {
				patch = patches.endCap,
				flags = V_PERPLAYER|hudTrans,
				x = backdrop2.x+backdrop2.scale.x,
				y = basePos.y*FU,
				scale = {
					x = (hellfire.endWidth*FU)/2,
					y = FixedDiv((patches.endCap.height+(hellfire.ringYOffset*(hellfire.ringWrapCount*2))), patches.endCap.height)/2
				}
			}
			hf.dataDraw(hudDrawer, "stretched", hpEnd)

			--Ring deficit counter.
			if hellfire.options.doRingSpill then
				local deficitString = "-"..hellfire.ringDeficit

				if hellfire.ringDeficit > 0 then
					if ply.jointime % 10 == 5 then
						hellfire.ringDefColor = V_REDMAP
					elseif ply.jointime % 10 == 0 then
						hellfire.ringDefColor = V_YELLOWMAP
					end
				else
					hellfire.ringDefColor = V_GREENMAP
					deficitString = " 0"
				end

				local deficitCounter = {
					text = deficitString,
					flags = V_MONOSPACE|V_PERPLAYER|hudTrans|hellfire.ringDefColor,
					align = "right",
					x = (basePos.x+(patches.healthPlate.width/2))-1,
					y = (basePos.y+middle)+(patches.healthPlate.height/2),
				}
				hf.dataDraw(hudDrawer, "string", deficitCounter)
			end

			--This is where the rings are drawn.
			for i=1,#hellfire.rings do
				if gui.visible then
					hellfire.rings[i].frame = 10
				else
					if hellfire.rings[i].doAnim == 2 then --Slow shine.
						hf.animateObj(hellfire.rings[i], ply.jointime, {ticsPerFrame=2, frames={7,10}, reverse=true}, function()
							hellfire.rings[i].doAnim = -1
						end)
					elseif hellfire.rings[i].doAnim == 1 then --Flash/regain animation.
						hf.animateObj(hellfire.rings[i], ply.jointime, {ticsPerFrame=1, frames={6,10}}, function()
							hellfire.rings[i].doAnim = -1
						end)
					elseif hellfire.rings[i].doAnim == 0 then --Shrivel/loss animation.
						hf.animateObj(hellfire.rings[i], ply.jointime, {ticsPerFrame=1, frames={11,16}}, function()
							hellfire.rings[i].frame = 0
							hellfire.rings[i].doAnim = -1
						end)
					else
						if not(hellfire.rings[i].isAnimating) then
							--Set the rings to specific frames for their states.
							if hellfire.rings[i].state == 1 then
								hellfire.rings[i].frame = 10
							elseif hellfire.rings[i].state == 0 then
								--Use the fillAmt for the animation frames; coded to be modular with different fillCaps.
								if hellfire.fillCap ~= 5 then
									local newFrame = hellfire.rings[i].fillAmt/hf.clamp((hellfire.fillCap/5), 1, FU)
									hellfire.rings[i].frame = newFrame
								else
									hellfire.rings[i].frame = hellfire.rings[i].fillAmt
								end
							end
						end
					end
				end
				local patch = hudDrawer.getSpritePatch(graphicPrefix.."HR", hellfire.rings[i].frame)

				local curRing = {
					patch = patch,
					flags = V_PERPLAYER|hudTrans,
					x = (hellfire.rings[i].x)*FU,
					y = (hellfire.rings[i].y)*FU,
					scale = FU/2
				}
				hf.dataDraw(hudDrawer, "scaled", curRing)
			end

			--Death animation for the main ring.
			if hellfire.health == 0 and hellfire.mainRing.animDone == false then
				hf.animateObj(hellfire.mainRing, ply.jointime, {ticsPerFrame=1, frames={1,8}}, function() hellfire.mainRing.animDone=true end)
			end
			
			local mainRing = {
				patch = patches.mainRing,
				flags = V_PERPLAYER|hudTrans,
				x = (basePos.x+30)*FU,
				y = (basePos.y+middle)*FU,
				scale = FU/2
			}
			hf.dataDraw(hudDrawer, "scaled", mainRing)

			gui.boundingBox = {
				x = {basePos.x*FU, 0},
				y = {basePos.y*FU, 0},
				scale = {
					x=((((patches.healthPlate.width/2)*FU)+backdrop1.scale.x)+(ringsWidth*FU))+(5*(hpEnd.scale.x*2)),
					y=backdrop1.scale.y
				}
			}
			gui.boundingBox.x[2] = gui.boundingBox.x[1]+gui.boundingBox.scale.x
			gui.boundingBox.y[2] = gui.boundingBox.y[1]+gui.boundingBox.scale.y
		end
	end
end

addHook("HUD", function(v, ply)
	if ply.hellfireHealth == nil then return end --Can't do anything yet...

	local hellfire = ply.hellfireHealth
	local gui = hellfire.hudposGUI

	-- local box = {
	-- 	patch = v.getSpritePatch("HFPX", 15),
	-- 	colormap = v.getColormap(nil, SKINCOLOR_BLACK),
	-- 	flags = V_TRANSLUCENT,
	-- 	x = gui.boundingBox.x[1],
	-- 	y = gui.boundingBox.y[1],
	-- 	scale = gui.boundingBox.scale
	-- }
	-- hf.dataDraw(v, "stretched", box)

	if gui.visible == false then --Default drawing function.
		hudHandler(v, ply)
		return
	end

	v.fadeScreen(0xFF00, 16)

	--Gotta add instructions on the controls!
	local instructions = {
		"Jump = Confirm",
		"Spin = Cancel",
		"Previous/Next Weapon = Scroll through presets",
		"Toss Flag = Toggle previews",
		"Movement/Click-n-Drag = Move HUD",
	}

	local txtObj = {
		text = table.concat(instructions, " | "),
		flags = V_YELLOWMAP|V_ALLOWLOWERCASE,
		align = "small-thin-fixed-center",
		x = FixedDiv(300*FU, 2*FU)+(10*FU),
		y = 200*FU
	}

	if input.gameControlDown(GC_JUMP) or input.gameControlDown(GC_SPIN) then
		local btn = "JUMP"
		if gui.priority == GC_SPIN then btn = "SPIN" end
		local ticTime = ply.jointime % 8
		txtObj.text = "LET GO OF "..btn.."!"
		txtObj.align = "fixed-center"
		txtObj.y = $-(10*FU)

		if ticTime >= 0 and ticTime <= 4 then
			txtObj.flags = V_REDMAP|V_ALLOWLOWERCASE
		end
	end

	if input.gameControlDown(GC_TOSSFLAG) and gui.lastInputTime == 0 then
		if gui.previewRingCount == 5 then
			gui.previewRingCount = 50
		else
			gui.previewRingCount = 5
		end

		gui.dragging = false
	end

	hf.dataDraw(v, "string", txtObj)
	
	hudHandler(v, ply)
	
	local cursorPos = {input.getCursorPosition()}
	cursorPos[1] = $*FU
	cursorPos[2] = ($+35)*FU
	
	local cursorBase = {
		patch = v.cachePatch("CROSHAI2"),
		flags = V_NOSCALEPATCH,
		x = cursorPos[1],
		y = cursorPos[2],
		scale = FU*v.dupx()
	}
	for i=1,2 do
		local newPart = {
			patch = v.getSpritePatch("HFPX", 2), --Aiming for palette color 98
			colormap = v.getColormap(nil, SKINCOLOR_GREEN),
			flags = V_NOSCALEPATCH,
			x = cursorPos[1]+((5*i)*FU),
			y = cursorPos[2]+((5*i)*FU),
			scale = FU*v.dupx()
		}
		
		hf.dataDraw(v, "scaled", newPart)
	end
	hf.dataDraw(v, "scaled", cursorBase)

	local offset = {x=(16*2)*FU, y=8*FU}
	--MASSIVE thanks to MarekkPie and hryx on the LÖVE forums for figuring out dragging!
	--(https://love2d.org/forums/viewtopic.php?t=7817)
	local checkLoc = {
		(gui.boundingBox.x[1]+offset.x)*v.dupx(),
		(gui.boundingBox.x[2]+offset.x)*v.dupx(),
		(gui.boundingBox.y[1]+offset.y)*v.dupy(),
		(gui.boundingBox.y[2]+offset.y)*v.dupy()
	}
	if cursorPos[1] > checkLoc[1] and cursorPos[1] < checkLoc[2] then
		if cursorPos[2] > checkLoc[3] and cursorPos[2] < checkLoc[4] then
			if mouse.buttons & MB_BUTTON1 then
				if not(gui.dragging) then
					gui.grabPoint = {x=cursorPos[1]-checkLoc[1], y=cursorPos[2]-checkLoc[3]}
				end
				if gui.lastMButtons ~= nil and gui.lastMButtons & MB_BUTTON1 == 0 then
					gui.dragging = true
				end
			else
				gui.dragging = false
			end
		end
	else
		if gui.dragging == true then
			gui.dragging = false
		end
	end

	local pressed = hf.getAllPressedGameControls()
	if gui.dragging
	and not(hf.isStringInTbl(GC_JUMP, pressed)) and not(hf.isStringInTbl(GC_SPIN, pressed))
	and not(hf.isStringInTbl(GC_JUMP, gui.lastGC)) and not(hf.isStringInTbl(GC_SPIN, gui.lastGC)) then
		local newPos = {
			x=(((cursorPos[1]-gui.grabPoint.x)/v.dupx())-offset.x)/FU,
			y=(((cursorPos[2]-gui.grabPoint.y)/v.dupy())-offset.y)/FU
		}
		hellfire.basePos = newPos
		hf.resetRings(hellfire, gui.previewRingCount)
	end

	if gui.lastMButtons ~= mouse.buttons then
		gui.lastMButtons = mouse.buttons
	end

	v.drawString(0, 150, "X: "..tostring(hellfire.basePos.x).."\nY: "..tostring(hellfire.basePos.y).."\nPreset #: "..tostring(hellfire.options.presetNum))
end)

addHook("PlayerThink", function(ply)
	if ply.hellfireHealth == nil then return end --Can't do anything yet...

	local hellfire = ply.hellfireHealth
	local gui = hellfire.hudposGUI

	if gui.visible then
		local pressed = hf.getAllPressedGameControls()

		if hf.tableCompare(gui.lastGC, pressed) == false then
			if not(hf.isStringInTbl(GC_JUMP, pressed)) and hf.isStringInTbl(GC_JUMP, gui.lastGC) and gui.priority == GC_JUMP then
				hf.modifyHUDPresets(hellfire.options.presetNum, hellfire.basePos)
				COM_BufInsertText(ply, "hf_closehudposGUI")
			elseif not(hf.isStringInTbl(GC_SPIN, pressed)) and hf.isStringInTbl(GC_SPIN, gui.lastGC) and gui.priority == GC_SPIN then
				COM_BufInsertText(ply, "hf_closehudposGUI")
			end
		end

		if not(hf.isStringInTbl(GC_JUMP, pressed)) and not(hf.isStringInTbl(GC_SPIN, pressed))
		and not(hf.isStringInTbl(GC_JUMP, gui.lastGC)) and not(hf.isStringInTbl(GC_SPIN, gui.lastGC)) then
			if hf.isStringInTbl(tostring(GC_WEAPONNEXT), pressed) then
				if hellfire.options.presetNum+1 >= 11 then
					hellfire.options.presetNum = 1
				else
					hellfire.options.presetNum = $+1
				end
				
				hf.loadHUDPreset(ply)
			elseif hf.isStringInTbl(tostring(GC_WEAPONPREV), pressed) then
				if hellfire.options.presetNum-1 < 1 then
					hellfire.options.presetNum = 10
				else
					hellfire.options.presetNum = $-1
				end

				hf.loadHUDPreset(ply)
			end
		end

		if gui.lastInputTime > 20 or hf.tableCompare(gui.lastGC, pressed) == false then
			if not(hf.isStringInTbl(GC_JUMP, pressed)) and not(hf.isStringInTbl(GC_SPIN, pressed))
			and not(hf.isStringInTbl(GC_JUMP, gui.lastGC)) and not(hf.isStringInTbl(GC_SPIN, gui.lastGC)) then
				for _,num in pairs(pressed) do
					hf.switch(num)
						.case(GC_FORWARD, function()
							hellfire.basePos.y = $-1
						end)
						.case(GC_BACKWARD, function()
							hellfire.basePos.y = $+1
						end)
						.case(GC_STRAFELEFT, function()
							hellfire.basePos.x = $-1
						end)
						.case(GC_STRAFERIGHT, function()
							hellfire.basePos.x = $+1
						end)
					.process()
				end

				hf.resetRings(hellfire, gui.previewRingCount)
			end
		end

		if input.gameControlDown(GC_SPIN) and input.gameControlDown(GC_JUMP) then
			if hf.isStringInTbl(GC_SPIN, gui.lastGC) and not(hf.isStringInTbl(GC_JUMP, gui.lastGC)) then
				gui.priority = GC_SPIN
			elseif hf.isStringInTbl(GC_SPIN, gui.lastGC) and not(hf.isStringInTbl(GC_JUMP, gui.lastGC)) then
				gui.priority = GC_JUMP
			elseif not(hf.isStringInTbl(GC_SPIN, gui.lastGC)) and not(hf.isStringInTbl(GC_JUMP, gui.lastGC)) then
				gui.priority = GC_SPIN
			end
		else
			if input.gameControlDown(GC_SPIN) then
				gui.priority = GC_SPIN
			elseif input.gameControlDown(GC_JUMP) then
				gui.priority = GC_JUMP
			end
		end
		
		if hf.anyGameControlDown() and hf.tableCompare(gui.lastGC, pressed) then
			gui.lastInputTime = $+1
		else
			gui.lastInputTime = 0
			gui.lastGC = pressed
		end

		ply.cmd.buttons = 0 --Clear buttons for mods like Battle, so buttons won't do anything.
	end
end)

--Have to put the FULLSTASIS in PostThinkFrame for mods like Battle, which mess with stasis.
addHook("PostThinkFrame", function()
	for ply in players.iterate() do
		if ply.hellfireHealth ~= nil and ply.hellfireHealth.hudposGUI.visible then
			ply.pflags = $ | PF_FULLSTASIS
		end
	end
end)

addHook("PlayerCmd", function(ply, cmd)
	if ply.hellfireHealth == nil then return end --Can't do anything yet...

	local hellfire = ply.hellfireHealth
	local gui = hellfire.hudposGUI

	if gui.visible then
		cmd.angleturn = gui.lockedCamAngles.angleturn
		cmd.aiming = gui.lockedCamAngles.aiming
	end
end)