#Requires -Version 5.1
<#
    claude_test_watcher.ps1 - Puente de verificacion para sesiones con Claude.

    Claude no puede ejecutar Dart/Flutter desde su entorno. Este script se
    deja corriendo en una ventana de PowerShell y ejecuta, bajo demanda, SOLO
    dos cosas: `flutter analyze` y `flutter test`. Nada mas.

    COMO SE USA
        powershell -ExecutionPolicy Bypass -File .\tools\claude_test_watcher.ps1

    Dejalo abierto. Para detenerlo: Ctrl+C.

    PROTOCOLO (archivos, sin red)
        temp/claude_sync/req/<id>.req   Claude escribe una peticion. Primera linea:
                                          analyze
                                          test
                                          test <ruta1> <ruta2> ...   (rutas bajo test/)
                                          pubget
        temp/claude_sync/res/<id>.log   Salida completa del comando.
        temp/claude_sync/res/<id>.done  Se crea al terminar; contiene el codigo de salida.

    Cualquier otra orden se rechaza y se anota en el .done con codigo 99.
#>
$ErrorActionPreference = "Continue"
Set-Location -Path (Join-Path $PSScriptRoot "..")

$reqDir = Join-Path (Get-Location) "temp\claude_sync\req"
$resDir = Join-Path (Get-Location) "temp\claude_sync\res"
New-Item -ItemType Directory -Force -Path $reqDir | Out-Null
New-Item -ItemType Directory -Force -Path $resDir | Out-Null

function Say([string]$m) { Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $m) }

Say "Vigilante listo. Carpeta de peticiones: $reqDir"
Say "Comandos permitidos: analyze | test [rutas] | pubget. Ctrl+C para salir."

# Latido: Claude lo lee para saber que el vigilante sigue vivo.
$heartbeat = Join-Path $resDir "heartbeat.txt"

while ($true) {
    try {
        (Get-Date).ToUniversalTime().ToString("o") | Set-Content -Path $heartbeat -Encoding ascii

        $req = Get-ChildItem -Path $reqDir -Filter "*.req" -File -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime | Select-Object -First 1
        if ($null -eq $req) { Start-Sleep -Seconds 2; continue }

        $id   = [System.IO.Path]::GetFileNameWithoutExtension($req.Name)
        $line = (Get-Content -Path $req.FullName -TotalCount 1).Trim()
        Remove-Item -Path $req.FullName -Force -ErrorAction SilentlyContinue

        $log  = Join-Path $resDir "$id.log"
        $done = Join-Path $resDir "$id.done"
        $running = Join-Path $resDir "$id.running"
        (Get-Date).ToString("o") | Set-Content -Path $running -Encoding ascii

        $parts = $line -split "\s+"
        $verb  = $parts[0].ToLower()
        $args  = @()
        $ok    = $true

        switch ($verb) {
            "analyze" { $args = @("analyze", "--no-pub") }
            "pubget"  { $args = @("pub", "get") }
            "test"    {
                $args = @("test", "--no-pub", "--reporter", "expanded")
                if ($parts.Length -gt 1) {
                    foreach ($p in $parts[1..($parts.Length - 1)]) {
                        # Solo rutas relativas dentro de test/, sin subir directorios.
                        $clean = $p -replace "\\", "/"
                        if ($clean -notmatch '^test/[A-Za-z0-9_./-]+$' -or $clean -match '\.\.') {
                            "Ruta rechazada: $p" | Set-Content -Path $log -Encoding utf8
                            $ok = $false; break
                        }
                        $args += $clean
                    }
                }
            }
            default {
                "Orden rechazada: '$line'. Permitidas: analyze | test [rutas] | pubget" |
                    Set-Content -Path $log -Encoding utf8
                $ok = $false
            }
        }

        if (-not $ok) {
            "99" | Set-Content -Path $done -Encoding ascii
            Remove-Item -Path $running -Force -ErrorAction SilentlyContinue
            Say "Peticion $id rechazada: $line"
            continue
        }

        Say "Peticion $id -> flutter $($args -join ' ')"
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        # cmd /c captura stdout+stderr con la misma codificacion; evita problemas
        # de PowerShell 5.1 al redirigir procesos nativos.
        $quoted = ($args | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
        cmd /c "flutter $quoted > `"$log`" 2>&1"
        $code = $LASTEXITCODE
        $sw.Stop()
        Add-Content -Path $log -Value ("`n[watcher] exit={0} elapsed={1:n1}s" -f $code, $sw.Elapsed.TotalSeconds) -Encoding utf8
        "$code" | Set-Content -Path $done -Encoding ascii
        Remove-Item -Path $running -Force -ErrorAction SilentlyContinue
        Say ("Peticion {0} terminada: exit={1} en {2:n1}s" -f $id, $code, $sw.Elapsed.TotalSeconds)
    }
    catch {
        Say "Error del vigilante: $($_.Exception.Message)"
        Start-Sleep -Seconds 2
    }
}
