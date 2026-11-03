# Optional workaround for a locally modified Flutter SDK.
# Reads the installed Git revision; writes ONLY under this project's .dart_tool.
# Run flutter pub get first. Subsequent Flutter commands must use --no-pub.
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$configPath = Join-Path $projectRoot '.dart_tool/package_config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Ejecuta flutter pub get antes de este script.'
}
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$sdkRoot = ([Uri]$config.flutterRoot).LocalPath
$target = Join-Path $projectRoot '.dart_tool/pristine_framework'
$archive = Join-Path $projectRoot '.dart_tool/pristine_framework.zip'
$packageNames = @('flutter', 'flutter_test', 'flutter_localizations')
$paths = @('LICENSE')
foreach ($name in $packageNames) {
    $paths += "packages/$name/lib"
    $paths += "packages/$name/pubspec.yaml"
}
& git -C $sdkRoot archive --format=zip "--output=$archive" HEAD -- @paths
if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer la revisión Git del SDK.' }
Expand-Archive -LiteralPath $archive -DestinationPath $target -Force
foreach ($package in $config.packages) {
    if ($package.name -in $packageNames) {
        $packagePath = Join-Path $target "packages/$($package.name)"
        $manifest = Get-Content -LiteralPath (Join-Path $packagePath 'pubspec.yaml') -Raw
        if ($manifest -notmatch 'sdk:\s*\^?(\d+\.\d+)') {
            throw "No se pudo leer la versión Dart de $($package.name)."
        }
        $package.languageVersion = $Matches[1]
        $package.rootUri = ([Uri]::new($packagePath + [IO.Path]::DirectorySeparatorChar)).AbsoluteUri
    }
}
$json = $config | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($configPath, $json, [Text.UTF8Encoding]::new($false))
Write-Output 'Paquetes originales preparados dentro de .dart_tool/pristine_framework. SDK intacto.'
Write-Output 'Usa flutter analyze --no-pub, flutter test --no-pub y flutter run --no-pub.'
