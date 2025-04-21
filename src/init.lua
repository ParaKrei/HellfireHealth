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
UPDATE: I am currently looking into a GUI to use...
so far it might be "Simple Custom Menu" (custom fork)...
but I want to find something better before committing.
]]

--Import JSON library--
rawset(_G, "hf_json", dofile("lib/json"))

--Freeslot stuff--
freeslot("SPR_HRHP") --Health Plate (Red)
freeslot("SPR_HRMR") --Melty Ring (Red)
freeslot("SPR_HRSR") --Stable Ring (Red)
freeslot("SPR_HRHR") --Half-Ring (Red)
freeslot("SPR_HYHP") --Health Plate (Yellow)
freeslot("SPR_HYMR") --Melty Ring (Yellow)
freeslot("SPR_HYSR") --Stable Ring (Yellow)
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
	["takisthefox"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["samus"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["basesamus"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["mario"]={isBanned=true, shieldHack=true, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["luigi"]={isBanned=true, shieldHack=true, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["sgimario"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["doomguy"]={isBanned=true, shieldHack=false, deathOverride=true, noDeathJingle=false, silentLoss=false},
	["echoes"]={isBanned=true, shieldHack=true, deathOverride=false, noDeathJingle=true, silentLoss=true},
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
Melted Ring = true #Sets if the main/last ring should be melted.
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
	["melted ring"]="meltRing",
	["see health bars"]="seeHealth",
	["auto save"]="autoSave",
})

--Misc. functions--
dofile("misc.lua")
dofile("hurtMsg.lua")

--Push entries in the default client list if not found--
local decoded = getClientList()

for name,tbl in pairs(defaultClient) do
	if decoded[name] == nil then
		modifyClientList(name, tbl)
	end
end

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