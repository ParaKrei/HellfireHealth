#Setup the parameters the script gets from the tasks.
param(
	#Sets the game executable path.
	[string]$gameExe = "",
	#Sets the file that has the mod's location stored.
	[string]$pathFile = "",
	#A list of mods to test with.
	[string]$mods = "",
	#The name of the map to warp to.
	[string]$mapName = "",
	#The name of the skin to start as (only works on warp).
	[string]$targetSkin = "",
	#Other arguments to pass to the game.
	[string]$otherArgs = ""
)

[string]$mainMod = Get-Content -Path $pathFile
[string]$warpStr = ""
[string]$skinStr = ""
if ($mapName -ne "")
{
	$warpStr = "-warp "+$mapName
	if ($targetSkin -ne "")
	{
		$skinStr = "+skin "+$targetSkin
	}
}

& $gameExe -file $mainMod $mods $otherArgs $warpStr $skinStr