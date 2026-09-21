<#
.SYNOPSIS
  Análisis ESTÁTICO del código fuente con la API de axe DevTools Linter (Deque).
  Es el equivalente "SonarQube pero de accesibilidad": no abre navegador,
  solo envía el código al endpoint /lint-source.

.NOTES
  Requiere una API key de axe DevTools Linter en la variable de entorno
  AXE_LINTER_API_KEY. El header es Authorization con la key directamente
  (sin prefijo "Bearer"), según la documentación de Deque.
#>
param(
    [string]$Path = './src',
    [string]$ApiUrl = 'https://axe-linter.deque.com/lint-source',
    [string]$OutDir = './axe-results',
    [switch]$FailOnViolations
)

$ErrorActionPreference = 'Stop'

$apiKey = $env:AXE_LINTER_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host '::warning::AXE_LINTER_API_KEY no está definida. Se omite el axe Linter.'
    exit 0
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Extensiones que soporta el linter
$files = Get-ChildItem -Path $Path -Recurse -File -Include *.html, *.htm, *.jsx, *.tsx, *.vue
$totalErrors = 0
$summary = @()

foreach ($file in $files) {
    Write-Host "Analizando $($file.FullName)"

    $body = @{
        source   = Get-Content -Raw -Path $file.FullName
        filename = $file.Name
    } | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod -Method Post -Uri $ApiUrl `
        -Headers @{ Authorization = $apiKey } `
        -ContentType 'application/json; charset=utf-8' `
        -Body $body

    # Guardamos la respuesta cruda
    $response | ConvertTo-Json -Depth 20 |
        Set-Content -Path (Join-Path $OutDir "linter-$($file.Name).json") -Encoding utf8

    # Formato esperado: { report: { errors: [ ... ] } }
    $errors = @()
    if ($response.report -and$response.report.errors) { 
        $errors = @($response.report.errors) 
    }

    foreach ($e in $errors) {$line = '?'
        if ($e.lineNumber) { $line =$e.lineNumber }

        $rule = 'regla'
        if ($e.ruleId) { $rule =$e.ruleId }

        $desc = ($e | ConvertTo-Json -Compress)
        if ($e.description) { $desc =$e.description }

        Write-Host "  [$rule] línea ${line}:$desc"
    }

    $totalErrors +=$errors.Count
    $summary += "| $($file.Name) | $($errors.Count) |"
}

# Resumen visible en la pestaña del workflow
if ($env:GITHUB_STEP_SUMMARY) {
    @('## axe DevTools Linter', '', '| Archivo | Errores |', '|---|---|') + $summary |
        Add-Content -Path $env:GITHUB_STEP_SUMMARY
}

Write-Host "Total de errores: $totalErrors"
if ($FailOnViolations -and$totalErrors -gt 0) {
    Write-Host "::error::Se encontraron $totalErrors errores de accesibilidad."
    exit 1
}