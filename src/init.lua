--[[
	Hellfire Saga's healthbar ported to SRB2.
	Created by ParaKrei.

	Graphics and sounds made by ParaKrei (sounds are heavily edited versions of sounds from the Genesis/Mega Drive Sonic games),
	Death jingle is by Michiru Yamane for Castlevania Bloodlines (the same one used in Hellfire Saga);
	ripped by DJ Squarewave from Project 2612, HQ conversion by archivologist from Internet Archive;
	URL: ("https://archive.org/details/md_music_castlevania_bloodlines/").

	QJSON library is by vurvdev (https://github.com/vurvdev/qjson).

	Menu system is by Lugent (https://mb.srb2.org/addons/lugents-menu-system.4119/).
]]

--[[
	TODO:
	Implement alignment types (left, right, top, and bottom) via a flag-like system. [Low-priority, might be 3.1]
]]

--Create global object to hold everything--
rawset(_G, "hf", {})

local consoleTag = [[
 |____OOOOOOOO____|_________________________________________________________|
 |___OOOOOOOOOO___|_________________________________________________________|
 |__OOOOOOOOOOOO__|_________________________________________________________|
 |_OOOOOOOOOOOOOO_|oo____oo_________ooo___ooo_____oooo__oo__________________|
 |_OOOOO_OOOOOOOO_|oo____oo__ooooo___oo____oo____oo_________oo_ooo___ooooo__|
 |OOOOOO_OO_OOOOOO|oo____oo_oo____o__oo____oo___ooooo___oo__ooo___o_oo____o_|
 |OOOO_O_O____OOOO|oooooooo_ooooooo__oo____oo___oo______oo__oo______ooooooo_|
 |OOOO___O____OOOO|oo____oo_oo_______oo____oo___oo______oo__oo______oo______|
 |OOOO________OOOO|oo____oo__ooooo__ooooo_ooooo_oo_____oooo_oo_______ooooo__|
 |OOOO________OOOO|_________________________________________________________|
 |OOOOO______OOOOO|oo____oo_________________ooo____oo____oo_________________|
 |OOOOOO____OOOOOO|oo____oo__ooooo___ooooo___oo____oo____oo_ooo_____________|
 |_OOOOOOOOOOOOOO_|oo____oo_oo____o_oo___oo__oo___oooo___ooo___o____________|
 |_OOOOOOOOOOOOOO_|oooooooo_ooooooo_oo___oo__oo____oo____oo____o____________|
 |__OOOOOOOOOOOO__|oo____oo_oo______oo___oo__oo____oo__o_oo____o____________|
 |__OOOOOOOOOOO___|oo____oo__ooooo___oooo_o_ooooo___ooo__oo____o____________|
 |__O_OOOOOO_O____|_________________________________________________________|
 |____O__OOO______|_________________________________________________________|
 |_______O________|_________________________________________________________|
            Mod created by ParaKrei, inspired by Hellfire Saga.

Original ASCII text generated through www.patorjk.com/software/taag (OS2 font)
 Ring ASCII generated through https://github.com/Kirilllive/ASCII_Art_Paint
]]

--Import JSON library--
hf["json"] = dofile("lib/qjson")

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
freeslot("SPR_HFPX") --A little pixel with palette colors 96-111 for drawing rectangles
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
if hf["bars"] == nil then
	hf["bars"] = {}
end

--Banned skins server table--
if hf["srvList"] == nil then
	hf["srvList"] = {}
end

--Compatibility function table--
if hf["compat"] == nil then
	hf["compat"] = {}
end

--Network syncs--
addHook("NetVars", function(net)
	hf.bars = net(hf.bars)
	hf.srvList = net(hf.srvList)
end)

--Create client list--
hf["defaultClient"] = {
	["takisthefox"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["samus"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["basesamus"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["mario"]={isBanned=true, shieldHack=true, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["luigi"]={isBanned=true, shieldHack=true, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["sgimario"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["n64mario"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["n64luigi"]={isBanned=true, shieldHack=false, deathOverride=false, noDeathJingle=false, silentLoss=false},
	["doomguy"]={isBanned=true, shieldHack=false, deathOverride=true, noDeathJingle=false, silentLoss=false},
	["echoes"]={isBanned=true, shieldHack=true, deathOverride=false, noDeathJingle=true, silentLoss=true},
}

local tempCliList = io.openlocal("client/hf_clientList.txt", "r+")
if tempCliList == nil then
	tempCliList = io.openlocal("client/hf_clientList.txt", "w")
	tempCliList:write(hf.json.encode(hf.defaultClient))
	tempCliList:flush()
	tempCliList:close()
else
	tempCliList:close()
end

--Create client preferences--
hf["defaultPrefs"] = [[
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
	tempPrefs:write(hf.defaultPrefs)
	tempPrefs:flush()
	tempPrefs:close()
else
	tempPrefs:close()
end

hf["prefsMapping"] = {
	["hear death jingle"]="doDeathJingle",
	["ui skin"]="skin",
	["melted ring"]="meltRing",
	["see health bars"]="seeHealth",
	["auto save"]="autoSave",
}

--Misc. functions--
dofile("misc.lua")
dofile("hurtMsg.lua")

--Push entries in the default client list if not found--
local decoded = hf.getClientList()

for name,tbl in pairs(hf.defaultClient) do
	if decoded[name] == nil then
		hf.modifyClientList(name, tbl)
	end
end

--Create HUD position presets file--
hf["defaultHUDPos"] = {
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50},
	{x = -16, y = 50}
}

local tempHUDSets = io.openlocal("client/hf_hudPresets.txt", "r+")
if tempHUDSets == nil then
	tempHUDSets = io.openlocal("client/hf_hudPresets.txt", "w")
	tempHUDSets:write(hf.json.encode(hf.defaultHUDPos))
	tempHUDSets:flush()
	tempHUDSets:close()
else
	tempHUDSets:close()
end

--Fill up any missing presets--
local decoded = hf.getHUDPresets()

for num,tbl in pairs(hf.defaultHUDPos) do
	if decoded[num] == nil then
		hf.modifyHUDPresets(num, tbl)
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

--The settings menu--
if SUBVERSION >= 14 then --Since Lugent's Menu System uses "input.ignoregameinputs" it won't work in SRB2 versions before 2.2.14.
	dofile("lib/LugentMenuSystem.lua")
	dofile("menu.lua")
end

--Print the console tag after everything's loaded--
print(consoleTag)