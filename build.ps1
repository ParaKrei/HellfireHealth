#Setup the parameters the script gets from the tasks.
param(
	#Sets the mod name.
	[string]$modName = "MyMod",
	#Sets the suffix.
	[string]$suffix = "1",

	#Sets the export path.
	[string]$exportPath = "",
	#Sets the path that the path+file is stored for the test script.
	[string]$pathSave = "",

	#Sets if the mod if the "S" prefix is added to the filename.
	[string]$s = "false",
	#Sets if the mod if the "R" prefix is added to the filename.
	[string]$r = "false",
	#Sets if the mod if the "M" prefix is added to the filename.
	[string]$m = "false",
	#Sets if the mod if the "F" prefix is added to the filename.
	[string]$f = "false",
	#Sets if the mod if the "C" prefix is added to the filename.
	[string]$c = "false",
	#Sets if the mod if the "L" prefix is added to the filename.
	[string]$l = "false"
)

#Make the prefix.
[string[]]$prefixes = @("S","R","M","F","C","L")
[string[]]$modTypes = @($s,$r,$m,$f,$c,$l)
[string]$finalPrefix = ""

for ($i=0;$i -lt 6; $i++)
{
	if ($modTypes[$i].ToLower() -eq "true")
	{
		$finalPrefix += $prefixes[$i]
	}
}

#Make the filename.
[string]$finalFilename = $finalPrefix+"_"+$modName+"_"+$suffix

#Make the file.
$inst = @{
	Path = "./src/*"
	CompressionLevel = "Optimal"
	DestinationPath = $exportPath+"/"+$finalFilename+".pk3"
}
Compress-Archive @inst -Force
$finalFilename+".pk3" | Out-File -FilePath "$pathSave"