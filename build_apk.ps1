#Requires -Version 5.1
<#
    build_apk.ps1 - Genera la APK de DESARROLLO de BIO-G.

    Reemplaza a `flutter run` para las pruebas de hardware: produce un archivo
    .apk que se instala en el telefono y corre solo, sin PC conectada.

    USO NORMAL (lo unico que necesitas casi siempre):
        .\build_apk.ps1

    OPCIONES:
        .\build_apk.ps1 -Install      Instala en el telefono USB al terminar.
        .\build_apk.ps1 -Clean        Borra build/ antes (lento; solo si algo
                                      quedo corrupto tras cambiar de SDK).
        .\build_apk.ps1 -SplitAbi     Una APK por arquitectura (mas chicas,
                                      pero tienes que elegir la correcta).
        .\build_apk.ps1 -SkipAnalyze  Se salta el analisis estatico previo.

    Si PowerShell bloquea el script:
        powershell -ExecutionPolicy Bypass -File .\build_apk.ps1
#>
[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$Install,
    [switch]$SplitAbi,
    [switch]$SkipAnalyze,
    # Misma llave que ya vive en run.ps1 y en el AndroidManifest.
    [string]$MapsApiKey = "AIzaSyCujhe2xUFhzPkfgj6PkQgTwfn2fcqHwBA"
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Step([string]$m) { Write-Host ""; Write-Host ">> $m" -ForegroundColor Cyan }
function Ok([string]$m)   { Write-Host "   ok   $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "   ojo  $m" -ForegroundColor Yellow }
function Die([string]$m)  { Write-Host ""; Write-Host "FALLO: $m" -ForegroundColor Red; exit 1 }

$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "=====================================================" -ForegroundColor White
Write-Host " BIO-G  |  build de APK de desarrollo" -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor White

# --------------------------------------------------------------------------
Step "1/6  Revisando que Flutter este disponible"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Die "No encuentro 'flutter' en el PATH. Abre una terminal nueva o agrega C:\src\flutter\bin al PATH."
}
try {
    $fv = (& flutter --version | Select-Object -First 1)
} catch {
    $fv = "(no pude leer la version, pero flutter existe)"
}
Ok "$fv"

# --------------------------------------------------------------------------
Step "2/6  Resolviendo dependencias (flutter pub get)"
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Warn "pub get fallo. Intento reparar la version de flutter_blue_plus..."
    flutter pub add flutter_blue_plus
    if ($LASTEXITCODE -ne 0) { Die "No se pudieron resolver las dependencias. Revisa el error de pub arriba." }
    flutter pub get
    if ($LASTEXITCODE -ne 0) { Die "pub get sigue fallando." }
    Ok "Dependencias reparadas (pub eligio la version compatible de flutter_blue_plus)."
} else {
    Ok "Dependencias listas."
}

# --------------------------------------------------------------------------
if ($Clean) {
    Step "3/6  flutter clean (pediste -Clean)"
    flutter clean
    flutter pub get
    Ok "Arbol de build limpio."
} else {
    Step "3/6  Build incremental (usa -Clean si algo quedo raro)"
    Ok "Saltado."
}

# --------------------------------------------------------------------------
if ($SkipAnalyze) {
    Step "4/6  Analisis estatico"
    Ok "Saltado (-SkipAnalyze)."
} else {
    Step "4/6  Analisis estatico (solo errores son fatales)"
    flutter analyze --no-fatal-infos --no-fatal-warnings
    if ($LASTEXITCODE -ne 0) {
        Die "Hay errores de Dart. Corrigelos antes de compilar (o usa -SkipAnalyze para ignorar y ver si aun asi compila)."
    }
    Ok "Sin errores de Dart."
}

# --------------------------------------------------------------------------
Step "5/6  Compilando APK release (esto tarda varios minutos la primera vez)"
$buildArgs = @(
    "build", "apk",
    "--release",
    "--dart-define=GOOGLE_MAPS_API_KEY=$MapsApiKey"
)
if ($SplitAbi) { $buildArgs += "--split-per-abi" }

Write-Host "   flutter $($buildArgs -join ' ')" -ForegroundColor DarkGray
& flutter @buildArgs
if ($LASTEXITCODE -ne 0) { Die "El build de Gradle/Flutter fallo. El error real esta arriba." }

# --------------------------------------------------------------------------
Step "6/6  Resultado"
$apkDir = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk"
$apks = @(Get-ChildItem -Path $apkDir -Filter "*release*.apk" -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -notlike "*.sha1" })
if ($apks.Count -eq 0) { Die "El build dijo que termino pero no encuentro ninguna APK en $apkDir" }

# Copia versionada, para saber siempre que build trae el telefono.
$version = "dev"
$vLine = Get-Content (Join-Path $PSScriptRoot "pubspec.yaml") |
         Where-Object { $_ -match "^version:\s*(\S+)" } |
         Select-Object -First 1
if ($vLine -and $vLine -match "^version:\s*(\S+)") { $version = $Matches[1] }
# '+' y otros caracteres raros fuera del nombre de archivo
$version = ($version -replace "[^0-9A-Za-z\.\-]", "_")
$stamp   = Get-Date -Format "yyyyMMdd-HHmm"
$distDir = Join-Path $PSScriptRoot "dist"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

Write-Host ""
Write-Host "APK generada:" -ForegroundColor Green
foreach ($a in $apks) {
    $mb = [math]::Round($a.Length / 1MB, 1)
    Write-Host ("   {0}   ({1} MB)" -f $a.FullName, $mb) -ForegroundColor White
    $suffix = if ($apks.Count -gt 1) { "-" + ($a.BaseName -replace "^app-", "" -replace "-release$", "") } else { "" }
    $copy = Join-Path $distDir ("BIO-G-{0}-{1}{2}.apk" -f $version, $stamp, $suffix)
    Copy-Item $a.FullName $copy -Force
    Write-Host ("   copia -> {0}" -f $copy) -ForegroundColor DarkGray
}

if ($Install) {
    Step "Instalando en el telefono conectado"
    if (Get-Command adb -ErrorAction SilentlyContinue) {
        adb install -r $apks[0].FullName
        if ($LASTEXITCODE -ne 0) { Warn "adb install fallo. Revisa que el telefono tenga depuracion USB activada y aceptada." }
        else { Ok "Instalada." }
    } else {
        flutter install --release
    }
} else {
    Write-Host ""
    Write-Host "Para instalarla:" -ForegroundColor Cyan
    Write-Host "   por USB    ->  adb install -r `"$($apks[0].FullName)`"" -ForegroundColor White
    Write-Host "   o a mano   ->  copia el .apk de dist\ al telefono y abrelo" -ForegroundColor White
    Write-Host "                  (hay que permitir 'instalar apps desconocidas')" -ForegroundColor DarkGray
}

$sw.Stop()
Write-Host ""
Write-Host ("Listo en {0:mm\:ss}." -f $sw.Elapsed) -ForegroundColor Green
