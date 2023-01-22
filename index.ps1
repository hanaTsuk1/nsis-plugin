param($list)

$pluginArray = $list.Split(",")

$validPluginArray = @("nsProcess")

for ($i = 0; $i -lt $pluginArray.Count; $i++) {
  if (!$validPluginArray.Contains($pluginArray[$i])) {
    throw "plugin `"$($pluginArray[$i])`" not found"
  }
}

$makensisPath = ""

try {
  $makensisPath = Get-Command makensis -Syntax -ErrorAction Stop
}
catch {
  throw "makensis command not found"
}

$nsisVersion = makensis /VERSION
$major = $nsisVersion[1]

if ($major -lt 3) {
  throw "only support nsis 3"
}

if (!$makensisPath.Contains("Bin")) {
  if ($makensisPath -like "*\scoop\shims\*") {
    $scoopRoot = (Get-Item $makensisPath).Directory.parent.FullName
    $makensisPath = Join-Path -Path $scoopRoot -ChildPath "apps\nsis\current\Bin\makensis.exe"
    $makensisPath
  }
  else {
    throw "unable to find the specific location of plugins installation ($makensisPath)"
  }
}

$root = (Get-Item $makensisPath).Directory.parent.FullName
$nsisIncludePath = Join-Path -Path $root -ChildPath "Include"
$nsisPluginsANSIPath = Join-Path -Path $root -ChildPath "Plugins\x86-ansi"
$nsisPluginsUNICODEPath = Join-Path -Path $root -ChildPath "Plugins\x86-unicode"

$download = "$HOME\Downloads"
$tempDownloadPath = "$download\nsis-plugin"
mkdir $tempDownloadPath -Force

foreach ($name in $pluginArray) {
  $url = "https://raw.githubusercontent.com/hanaTsuk1/nsis-plugin/master/plugins/$name.zip"
  $zipFile = "$tempDownloadPath\$(Split-Path -Path $url -Leaf)"
  Invoke-WebRequest -Uri $url -OutFile $zipFile
  Expand-Archive -Path $zipFile -DestinationPath $tempDownloadPath -Force

  $current = "$tempDownloadPath\$name"

  if ($name -eq "nsProcess") {
    Move-Item -Path "$current\nsProcess.nsh" -Destination "$nsisIncludePath\nsProcess.nsh" -Force
    Move-Item -Path "$current\nsProcess.dll" -Destination "$nsisPluginsANSIPath\nsProcess.dll" -Force
    Move-Item -Path "$current\nsProcessW.dll" -Destination "$nsisPluginsUNICODEPath\nsProcess.dll" -Force
  }
}


Remove-Item $tempDownloadPath -Recurse
