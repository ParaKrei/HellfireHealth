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
There might be a GUI coded in to modify settings AND preferences as well, since 2.2.14 will add in the ability to ignore player input with a variable.
SRC: ("https://git.do.srb2.org/STJr/SRB2/-/merge_requests/2185").
]]

--Import JSON library--
rawset(_G, "hf_json", dofile("lib/json"))

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

--Create client and server lists--
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
	tempCliList:write(hf_json.encode(defaultClient))
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

--Create client preferences--
local defaultPrefs = [[
#Hello, ParaKrei here. Welcome to YOUR preferences file!
#This is where the options that you changed for your tastes are saved.
#I've made this as easy to read, modify and understand as much as possible!

#All you need to do is to modify the values at the end of the equals (=) sign.
#The values each option accepts are the same as the "set" command in-game!
#My mod will read these values and apply it to your game when you spawn,
#OR when you tell the game to reload these values.

#I would advise not messing with anything before the equals sign,
#as your values could get lost as the mod won't be able to read them anymore.
#Also, do NOT remove the equals sign, or everything WILL break!

#You can also put in your own commands by using the HASH (#) sign like I've been...
#in case you want to put something here.

Hear Death Jingle = true #Should be self-explanatory.
UI Skin = red #The color of the health bars (both HUD and above players).
See Health Bars = true #Should be self-explanatory.
Auto Save = true #Should be self-explanatory.
]]

local tempPrefs = io.openlocal("client/hf_prefs.txt", "r+")
if tempPrefs == nil then
	tempPrefs = io.openlocal("client/hf_prefs.txt", "w")
	tempPrefs:write(defaultPrefs)
	tempPrefs:flush()
	tempPrefs:close()
else
	tempPrefs:close()
end

rawset(_G, "hfPrefsMapping", {
	["hear death jingle"]="doDeathJingle",
	["ui skin"]="skin",
	["see health bars"]="seeHealth",
	["auto save"]="autoSave",
})

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