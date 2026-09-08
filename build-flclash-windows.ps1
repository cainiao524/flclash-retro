$ErrorActionPreference = 'Stop'
$windowsProject = Join-Path $PSScriptRoot 'flclash-official'
$windowsTools = Join-Path $PSScriptRoot '.tools'
$windowsFlutter = Join-Path $windowsTools 'flutter\bin\flutter.bat'
$windowsCargo = Join-Path $env:USERPROFILE '.cargo\bin'

foreach ($requiredPath in @($windowsFlutter, (Join-Path $windowsCargo 'cargo.exe'), (Join-Path $windowsTools 'go\bin\go.exe'))) {
  if (-not (Test-Path -LiteralPath $requiredPath)) {
    throw "缺少构建工具：$requiredPath"
  }
}

$env:PUB_CACHE = Join-Path $windowsTools 'pub-cache'
$env:GOROOT = Join-Path $windowsTools 'go'
$env:GOPATH = Join-Path $windowsTools 'go-path'
$env:CARGO_HOME = Join-Path $windowsTools 'cargo'
$env:GOPROXY = 'https://goproxy.cn,direct'
$env:GOSUMDB = 'sum.golang.google.cn'
$env:HTTP_PROXY = 'http://127.0.0.1:7890'
$env:HTTPS_PROXY = 'http://127.0.0.1:7890'
$env:ALL_PROXY = 'http://127.0.0.1:7890'
$env:Path = "$(Join-Path $windowsTools 'flutter\bin');$(Join-Path $windowsTools 'go\bin');$windowsCargo;$env:Path"

Push-Location $windowsProject
try {
  & $windowsFlutter build windows --release --dart-define-from-file env.json
  if ($LASTEXITCODE -ne 0) { throw 'Windows 构建失败。' }
  $windowsBundle = Join-Path $windowsProject 'build\windows\x64\runner\Release'
  foreach ($requiredFile in @('FlClash.exe', 'FlClashCore.exe', 'FlClashHelperService.exe', 'manifest.json', 'flutter_windows.dll')) {
    if (-not (Test-Path -LiteralPath (Join-Path $windowsBundle $requiredFile))) {
      throw "构建产物不完整：$requiredFile"
    }
  }
  $windowsVswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  $windowsVsPath = & $windowsVswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
  $windowsRedist = Get-ChildItem -Path (Join-Path $windowsVsPath 'VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT') -Directory | Sort-Object FullName -Descending | Select-Object -First 1
  if ($null -eq $windowsRedist) { throw '找不到可随程序分发的 C++ 运行库。' }
  Get-ChildItem -LiteralPath $windowsRedist.FullName -Filter '*.dll' | Copy-Item -Destination $windowsBundle
  Copy-Item -LiteralPath (Join-Path $windowsProject 'LICENSE') -Destination $windowsBundle
  $windowsDist = Join-Path $windowsProject 'dist'
  if (-not (Test-Path -LiteralPath $windowsDist)) {
    New-Item -ItemType Directory -Path $windowsDist | Out-Null
  }
  $windowsArchive = Join-Path $windowsDist 'FlClash-retro-0.8.96-windows-x64.zip'
  Compress-Archive -Path (Join-Path $windowsBundle '*') -DestinationPath $windowsArchive -Force
  Write-Output "Windows 便携版已生成：$windowsArchive"
} finally {
  Pop-Location
}
