--[[
HUD handler.
]]

--Had to put in manual scaling for the four functions below, since SRB2's scaling doesn't give me enough fine control.
--Setting up a function to pre-multiply the positions in drawScaled.
local function scaledDraw_MultPos(v, x, y, scale, patch, flags, colormap)
	if flags == nil then flags = 0 end
	if colormap == nil then colormap = v.getColormap(TC_DEFAULT) end

	v.drawScaled((FU*x)*v.dupx(), (FU*y)*v.dupx(), scale, patch, V_NOSCALESTART|flags)
end

--Setting up a function to pre-multiply the values in drawCropped AND make a simpler function for my needs.
local function simpleCroppedDraw(v, x, y, scale, patch, flags, w, h)
	if flags == nil then flags = 0 end

	v.drawCropped((FU*x)*v.dupx(), (FU*y)*v.dupx(), scale, scale, patch, V_NOSCALESTART|flags, v.getColormap(TC_DEFAULT), w, h, w*FU, h*FU)
end

--Setting up a function to pre-multiply the values in drawStretched AND make a simpler function for my needs.
local function simpleStretchedDraw(v, x, y, scale, patch, width, height, flags)
	if flags == nil then flags = 0 end

	v.drawStretched((FU*x)*v.dupx(), (FU*y)*v.dupx(), (scale*width), (scale*height), patch, V_NOSCALESTART|flags, v.getColormap(TC_DEFAULT))
end

--The built-in drawFill isn't enough for my purposes, so I'm making my own! (It turned out to be simpler to make than I thought.)
local function boxDraw(v, x, y, width, height, flags)
	if flags == nil then flags = 0 end

	local patch = v.getSpritePatch("HFBP")

	v.drawStretched((FU*x)*v.dupx(), (FU*y)*v.dupx(), (FU*width)/5, (FU*height)/2, patch, V_NOSCALESTART|flags, v.getColormap(TC_DEFAULT))
end

--Making my own animation handler.
local function animateObj(i, target, tics, ticRate, startFrame, endFrame, onCompleteFunc)
	local frameDiff = 1
	if target.frame ~= startFrame and target.isAnimating == false then target.frame = startFrame end --Set the frame to the starting frame in the args.
	if startFrame < endFrame and target.isAnimating == false then frameDiff = -1 end --Set the frame advance to negative if the starting frame is less than ending frame.
	target.isAnimating = true --Ensures that animations only play once and don't play over each other.

	--Stop the animation if it's hit the endFrame.
	if target.frame >= endFrame then
		target.frame = endFrame
		target.isAnimating = false

		--A little something to allow code execution after animation completion.
		if onCompleteFunc ~= nil then
			onCompleteFunc()
		end
	elseif target.frame < endFrame then
		if tics % ticRate == 0 then
			target.frame = $+frameDiff
		end
	end
end

--This is where the HUD is drawn.
local function hudHandler(hudDrawer, ply)
	local hellfire = ply.hellfireHealth
	if objectExists(ply.mo) == false then return end --Don't draw anything if the player mobj doesn't exist.

	if not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		local graphicPrefix = ""
		if hellfire.options.skin == "red" then
			graphicPrefix = "HR"
		elseif hellfire.options.skin == "yellow" then
			graphicPrefix = "HY"
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
			hudTrans = V_HUDTRANSHALF
			hellfire.transStuff.overallAlpha = 1
		end

		--Stop drawing stuff once the alpha hits the max value.
		if hellfire.transStuff.overallAlpha < 10 then
			local healthPlate = hudDrawer.getSpritePatch(graphicPrefix.."HP", hellfire.healthPlate.frame)
			local mainRing = hudDrawer.getSpritePatch(graphicPrefix.."MR", hellfire.mainRing.frame)
			local basePos = hellfire.basePos

			--Death animation for the base-plate.
			if hellfire.health == 0 and hellfire.healthPlate.animDone == false then
				animateObj(i, hellfire.healthPlate, ply.jointime, 1, 1, 6, function() hellfire.healthPlate.animDone=true end)
			end
			--Getting this correct was a pain, ESPECIALLY since the *2 I put in earlier came back to bite me.
			local ringsWidth = clamp(((8*#hellfire.rings)+((16*2)*#hellfire.rings)), 0, FU)
			if #hellfire.rings >= hellfire.ringWrapAt then
				ringsWidth = clamp(((8*(hellfire.ringWrapAt-1))+((16*2)*(hellfire.ringWrapAt-1))), 0, FU)
			end

			local middle = ((16+4)*hellfire.ringWrapCount)/2
			scaledDraw_MultPos(hudDrawer, basePos.x, basePos.y+middle, FU/2, healthPlate, V_PERPLAYER|hudTrans) --HP Head.

			local boxHeight = 35+(((16+4)*2)*hellfire.ringWrapCount)
			boxDraw(hudDrawer, (basePos.x+(54/2)), basePos.y, ((54/2)+(32*2))+(basePos.x+29), boxHeight, V_PERPLAYER|hudTrans) --Main-Ring backdrop + Half-Rings connector.
			boxDraw(hudDrawer, (basePos.x+54), basePos.y, ringsWidth, boxHeight, V_PERPLAYER|hudTrans) --Half-Rings backdrop.

			--For a while, I couldn't get the position correct, UNTIL I remembered that I divided the boxWidth by 5 in the boxDraw function.
			simpleStretchedDraw(hudDrawer, (basePos.x+54)+(ringsWidth/5), basePos.y+(hellfire.ringWrapCount+(1/3)), FU/2, hudDrawer.getSpritePatch("HFPE", 0), hellfire.endWidth, hellfire.ringWrapCount+1, V_PERPLAYER|hudTrans) --HP End.

			--Ring deficit counter.
			if ply.jointime % 10 == 5 then
				hellfire.ringDefColor = V_REDMAP
			elseif ply.jointime % 10 == 0 then
				hellfire.ringDefColor = V_YELLOWMAP
			end
			if hellfire.ringDeficit > 0 then
				local xOffset = (5*(#tostring(hellfire.ringDeficit)-1))
				hudDrawer.drawString((basePos.x-25)-xOffset, (basePos.y+10)+middle, "-"..hellfire.ringDeficit, V_MONOSPACE|V_PERPLAYER|hudTrans|hellfire.ringDefColor)
			end

			--This is where the rings are drawn.
			for i=1,#hellfire.rings do
				if hellfire.rings[i].doFlash then --Flash/regain animation.
					animateObj(i, hellfire.rings[i], ply.jointime, 1, 6, 10, function()
						hellfire.rings[i].doFlash = false
					end)
				elseif hellfire.rings[i].doShrivel then --Shrivel/loss animation.
					animateObj(i, hellfire.rings[i], ply.jointime, 1, 11, 16, function()
						hellfire.rings[i].frame = 0
						hellfire.rings[i].doShrivel = false
					end)
				else
					--Set the rings to specific frames for their states.
					if hellfire.rings[i].state == "filled" then
						hellfire.rings[i].frame = 10
					elseif hellfire.rings[i].state == "empty" then
						--Use the fillAmt for the animation frames; coded to be modular with different fillCaps.
						if hellfire.fillCap ~= 5 then
							local newFrame = hellfire.rings[i].fillAmt/clamp((hellfire.fillCap/5), 1, FU)
							hellfire.rings[i].frame = newFrame
						else
							hellfire.rings[i].frame = hellfire.rings[i].fillAmt
						end
					end
				end
				local patch = hudDrawer.getSpritePatch(graphicPrefix.."HR", hellfire.rings[i].frame)

				scaledDraw_MultPos(hudDrawer, hellfire.rings[i].x, hellfire.rings[i].y, FU/2, patch, V_PERPLAYER|hudTrans)
			end

			--Death animation for the main ring.
			if hellfire.health == 0 and hellfire.mainRing.animDone == false then
				animateObj(i, hellfire.mainRing, ply.jointime, 1, 1, 8, function() hellfire.mainRing.animDone=true end)
			end
			scaledDraw_MultPos(hudDrawer, basePos.x+30, basePos.y+middle, FU/2, mainRing, V_PERPLAYER|hudTrans)
		end
	end
end

addHook("HUD", hudHandler)