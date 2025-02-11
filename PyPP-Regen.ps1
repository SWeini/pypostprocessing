﻿Param(
    [String]$FactorioPath = "C:\Games\Factorio\bin\x64\factorio.exe",
    [String]$FactorioDataPath = "$env:APPDATA\Factorio",
    [String]$FactorioModsPath = "$FactorioDataPath\mods.dev"
)
$FactorioArgs = "$FactorioPath --mod-directory $FactorioModsPath --benchmark notafile" #Stand in for "load then exit"
$ModCombinations = (Get-ChildItem "$FactorioModsPath\pypostprocessing\cached-configs" -Exclude run.lua).BaseName
$StartToken = "<BEGINPYPP>" #\1
$EndToken = "<ENDPYPP>" #\2
# Enable PyPP dev mode
$PyPPConfigPath = "$FactorioModsPath\pypostprocessing\settings-updates.lua"
$PyPPPrevConfig = Get-Content -Path $PyPPConfigPath -Raw
$PyPPConfig = $PyPPPrevConfig.Replace('data.raw["bool-setting"]["pypp-dev-mode"].forced_value  = false', 'data.raw["bool-setting"]["pypp-dev-mode"].forced_value  = true')
$PyPPConfig = $PyPPConfig.Replace('data.raw["bool-setting"]["pypp-create-cache"].forced_value  = false', 'data.raw["bool-setting"]["pypp-create-cache"].forced_value  = true')
Set-Content -Path $PyPPConfigPath -Value $PyPPConfig -Encoding UTF8 -NoNewline
$ModListJson = "$FactorioModsPath\mod-list.json"
ForEach($ModCombination in $ModCombinations){
    $ModList = $ModCombination -split "\+"
    $BaseMods = @(
        "base",
        "stdlib",
        "pypostprocessing",
        "pyalienlifegraphics",
        "pyalienlifegraphics2",
        "pyalienlifegraphics3",
        "pyalternativeenergygraphics",
        "pycoalprocessinggraphics",
        "pyfusionenergygraphics",
        "pyhightechgraphics",
        "pypetroleumhandlinggraphics",
        "pyraworesgraphics"
    )
    $FullModList = "$ModCombination+$($BaseMods -join '+')" -split "\+"
    $ModListContent = (Get-Content $ModListJson -Raw).Replace("true", "false")
    $Entry = $ModListContent.Substring(35, 38)
    ForEach($Mod in $FullModList){
        $ModEntry = $Entry.Replace("base", $Mod)
        $ModListContent = $ModListContent.Replace($ModEntry, $ModEntry.Replace("false", "true"))
    }
    #Set-Content -Path (Split-Path -Path $FactorioPath -Parent) -Value "427520" -Encoding UTF8 -NoNewline -ErrorAction SilentlyContinue
    Set-Content -Path "$FactorioModsPath\mod-list.json" -Value $ModListContent -Encoding UTF8 -NoNewline
    Write-Output "Generating for mod set $ModCombination"
    Start-Process "cmd" -ArgumentList "/c start `"`" $FactorioPath $FactorioArgs" -WorkingDirectory (Split-Path -Path $FactorioPath -Parent) -Wait
    $LogFile = Get-Content -Path "$FactorioDataPath\factorio-current.log" -Raw
    $StartPos = $LogFile.IndexOf($StartToken)
    if($StartPos -gt 0){
        $StartPos += $StartToken.Length
        $SubsectionLength = ($LogFile.IndexOf($EndToken) - $StartPos)
        $Content = $LogFile.Substring($StartPos, $SubsectionLength)
        Set-Content -Path "$FactorioModsPath\pypostprocessing\cached-configs\$ModCombination.lua" -Value $Content -Encoding UTF8 -NoNewline
        Write-Output "Finished generating for mod set $ModCombination"
    }else{
        Write-Warning -Message "Mod Set $ModCombination did not load successfully"
    }
}
Set-Content -Path $PyPPConfigPath -Value $PyPPPrevConfig -Encoding UTF8 -NoNewline
$PyPPPrevConfig | Out-File -FilePath $PyPPConfigPath -Encoding utf8
pause