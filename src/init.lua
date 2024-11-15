--[[
Hellfire Saga's healthbar ported to SRB2.
Created by ParaKrei.

Graphics and sounds made by ParaKrei (sounds are heavily edited versions of sounds from the Genesis/Mega Drive Sonic games),
Death jingle is by Michiru Yamane for Castlevania Bloodlines (the same one used in Hellfire Saga);
ripped by DJ Squarewave from Project 2612, HQ conversion by archivologist from Internet Archive;
URL: ("https://archive.org/details/md_music_castlevania_bloodlines/").

JSON library is by rxi (https://github.com/rxi/json.lua).
]]

--[[
There might be a GUI coded in to modify settings as well, since 2.2.14 will add in the ability to ignore player input with a variable.
SRC: ("https://git.do.srb2.org/STJr/SRB2/-/merge_requests/2185").
]]

--Import JSON library--
rawset(_G, "json", dofile("lib/json"))

--Freeslot stuff--
freeslot("SPR_HRHP") --Health Plate (Red)
freeslot("SPR_HRMR") --Main Ring (Red)
freeslot("SPR_HRHR") --Half-Ring (Red)
freeslot("SPR_HYHP") --Health Plate (Yellow)
freeslot("SPR_HYMR") --Main Ring (Yellow)
freeslot("SPR_HYHR") --Half-Ring (Yellow)
freeslot("SPR_HFPE") --Health Plate End
freeslot("SPR_HFBP") --A little black pixel for drawing rectangles
freeslot("sfx_hfloss") --Health loss SFX
sfxinfo[sfx_hfloss].caption = "\x85\bHealth Ring loss\x80"
freeslot("sfx_hfgain") --Health gain SFX
sfxinfo[sfx_hfgain].caption = "\x82\bHealth Ring gain\x80"
freeslot("sfx_hffill") --Health fill SFX
sfxinfo[sfx_hffill].caption = "\x87\bHealth Ring fill\x80"

--Health bar stuff--
freeslot("MT_HFBAR")
mobjinfo[MT_HFBAR] = {
	doomednum = -1,
	spawnstate = S_SPAWNSTATE,
	height = FU,
	flags = MF_SCENERY|MF_NOBLOCKMAP|MF_NOCLIPTHING|MF_NOGRAVITY
}
freeslot("SPR_HRHB") --Health Bar (Red)
freeslot("SPR_HYHB") --Health Bar (Yellow)

--Health bar table--
if HFBars == nil then
	rawset(_G, "HFBars", {})
end

if HFSrvList == nil then
	rawset(_G, "HFSrvList", {})
end

--Network syncs--
addHook("NetVars", function(net)
	HFBars = net(HFBars)
	HFSrvList = net(HFSrvList)
end)

--Read/create client and server lists--
local defaultClient = {
	["takisthefox"]={isBanned=true, shieldHack=false, deathOverride=false},
	["samus"]={isBanned=true, shieldHack=false, deathOverride=false},
	["basesamus"]={isBanned=true, shieldHack=false, deathOverride=false},
	["mario"]={isBanned=true, shieldHack=true, deathOverride=false},
	["luigi"]={isBanned=true, shieldHack=true, deathOverride=false},
	["sgimario"]={isBanned=true, shieldHack=false, deathOverride=false},
	["doomguy"]={isBanned=true, shieldHack=false, deathOverride=true}
}

local tempCliList = io.openlocal("client/hf_clientList.txt", "r+")
if tempCliList == nil then
	tempCliList = io.openlocal("client/hf_clientList.txt", "w")
	tempCliList:write(json.encode(defaultClient))
	tempCliList:flush()
	tempCliList:close()
else
	tempCliList:close()
end

--Disabled until I figure out how to do this properly.--
-- local tempSrvList = io.openlocal("hf_serverList.txt", "r+")
-- if tempSrvList == nil then
-- 	tempSrvList = io.openlocal("hf_serverList.txt", "w")
-- 	tempSrvList:write("")
-- 	tempSrvList:flush()
-- 	tempSrvList:close()
-- else
-- 	tempSrvList:close()
-- end

--Misc. functions--
dofile("misc.lua")
dofile("hurtMsg.lua")

--Console commands + cvars--
dofile("console.lua")

--The ACTUAL health system--
dofile("main.lua")

--Health bar--
dofile("healthBar.lua")

--HUD handler--
dofile("hud.lua")

--Compatibility stuff--
dofile("compat.lua")

--Server list stuff
--fetchServerList()