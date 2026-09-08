param(
  [ValidateSet('debug', 'release')]
  [string]$Mode = 'release',
  [switch]$SplitPerAbi
)

$workspaceRoot = $PSScriptRoot
$projectRoot = Join-Path $PSScriptRoot 'flclash-official'
if (-not (Test-Path (Join-Path $projectRoot 'pubspec.yaml'))) {
  throw '找不到 flclash-official 源码目录。'
}

$flutter = Join-Path $workspaceRoot '.tools\flutter\bin\flutter.bat'
$dart = Join-Path $workspaceRoot '.tools\flutter\bin\dart.bat'
$sdk = Join-Path $workspaceRoot '.tools\android'
$ndk = Join-Path $sdk 'ndk\28.2.13676358'
$pubCache = Join-Path $workspaceRoot '.tools\pub-cache'
$goRoot = Join-Path $workspaceRoot '.tools\go'
$goPath = Join-Path $workspaceRoot '.tools\go-path'
$java = Join-Path ${env:ProgramFiles} 'Java\jdk-21\bin\java.exe'

foreach ($path in @($flutter, $dart, $sdk, $ndk, $java)) {
  if (-not (Test-Path $path)) {
    throw "缺少项目内工具或路径：$path"
  }
}

$env:PUB_CACHE = $pubCache
$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_HOME = $sdk
$env:ANDROID_NDK = $ndk
$env:GOROOT = $goRoot
$env:GOPATH = $goPath
$env:GOPROXY = 'https://goproxy.cn,direct'
$env:GOSUMDB = 'sum.golang.google.cn'
$env:HTTP_PROXY = 'socks5://127.0.0.1:7890'
$env:HTTPS_PROXY = 'socks5://127.0.0.1:7890'
$env:ALL_PROXY = 'socks5://127.0.0.1:7890'
$env:Path = "$(Join-Path $workspaceRoot '.tools\flutter\bin');$(Join-Path $workspaceRoot '.tools\go\bin');$(Join-Path $workspaceRoot '.tools\cmdline-tools\latest\bin');$(Join-Path $pubCache 'bin');$env:Path"

Push-Location $projectRoot
try {
  if ((Test-Path (Join-Path $projectRoot '.git')) -and (Test-Path (Join-Path $projectRoot '.gitmodules'))) {
    git -c http.proxy=socks5h://127.0.0.1:7890 submodule update --init --recursive
  }
  & $flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'Flutter 依赖安装失败。' }
  $buildArgs = @('build', 'apk', "--$Mode", '--dart-define-from-file', 'env.json', '--build-name', '0.8.96', '--build-number', '2026081701')
  if ($SplitPerAbi) { $buildArgs += '--split-per-abi' }
  & $flutter @buildArgs
  if ($LASTEXITCODE -ne 0) { throw 'APK 打包失败。' }
} finally {
  Pop-Location
}
