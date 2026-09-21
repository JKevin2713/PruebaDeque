<#
.SYNOPSIS
  Análisis DINÁMICO (en navegador) con @axe-core/cli, el motor open source de Deque.
  No requiere cuenta ni API key. Sirve para probar que el pipeline funciona.
#>
param(
    [string[]]$Pages = @('index.html', 'con-errores.html'),
    [int]$Port = 8080,
    [string]$OutDir = './axe-results',
    [switch]$FailOnViolations
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$server = & "$PSScriptRoot/Start-LocalServer.ps1" -Root './src' -Port $Port
$failed = $false
$summary = @()

try {
    foreach ($page in $Pages) {
        $url = "http://localhost:$Port/$page"
        $json = Join-Path $OutDir "axe-core-$page.json"
        Write-Host "Escaneando $url"

        $cliArgs = @('--yes', '@axe-core/cli', $url,
                     '--tags', 'wcag2a,wcag2aa,wcag21a,wcag21aa',
                     '--save', $json)

        # En los runners de GitHub, chromedriver ya viene instalado.
        if ($env:CHROMEWEBDRIVER) {
            $cliArgs += @('--chromedriver-path', (Join-Path $env:CHROMEWEBDRIVER 'chromedriver'))
        }

        & npx @cliArgs
        $code = $LASTEXITCODE   # Nota: el conteo real se toma del JSON guardado

        $count = 0
        if (Test-Path $json) {
            $data = Get-Content -Raw $json | ConvertFrom-Json
            # El JSON es un arreglo de resultados; cada uno tiene "violations".
            foreach ($r in @($data)) { $count += @($r.violations).Count }
        }
        $summary += "| $page | $count |"
        if ($count -gt 0) { $failed = $true }
    }
}
finally {
    Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
}

if ($env:GITHUB_STEP_SUMMARY) {
    @('## axe-core (navegador)', '', '| Página | Reglas violadas |', '|---|---|') + $summary |
        Add-Content -Path $env:GITHUB_STEP_SUMMARY
}

if ($FailOnViolations -and $failed) {
    Write-Host '::error::axe-core encontró violaciones de accesibilidad.'
    exit 1
}
