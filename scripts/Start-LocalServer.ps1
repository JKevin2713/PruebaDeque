<#
.SYNOPSIS
  Levanta un servidor estático local (http-server) para poder escanear las páginas.
  Devuelve el proceso para que el llamador lo detenga al terminar.
#>
param(
    [string]$Root = './src',
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'

$proc = Start-Process -FilePath 'npx' `
    -ArgumentList @('--yes', 'http-server', $Root, '-p', $Port, '-s') `
    -PassThru -NoNewWindow

# Esperar hasta 30 s a que responda.
$url = "http://localhost:$Port/index.html"
for ($i = 0; $i -lt 30; $i++) {
    try {
        Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2 | Out-Null
        Write-Host "Servidor listo en $url"
        return $proc
    } catch {
        Start-Sleep -Seconds 1
    }
}
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
throw "El servidor local no respondió en $url"
