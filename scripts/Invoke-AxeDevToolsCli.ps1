<#
.SYNOPSIS
  Análisis con el CLI comercial "axe DevTools for Web" (@axe-devtools/cli).

.DESCRIPTION
  Requisitos (todos secretos/variables de entorno):
    AGORA_EMAIL            correo de tu cuenta de Deque Agora
    AGORA_IDENTITY_TOKEN   Identity Token generado en agora.dequecloud.com
  Opcionales (para subir resultados a Axe Developer Hub):
    AXE_DEVHUB_API_KEY     API key personal (Axe Account > API keys)
    AXE_DEVHUB_PROJECT_ID  ID del proyecto en Developer Hub
  Si estas dos últimas están definidas, el CLI envía los resultados solo.

  NOTA: el CLI usa Firefox por defecto (geckodriver ya viene en los runners
  ubuntu-latest). Revisa la "CLI Reference" de Deque para más opciones.
#>
param(
    [string[]]$Pages = @('index.html', 'con-errores.html'),
    [int]$Port = 8080,
    [string]$OutDir = './axe-results'
)

$ErrorActionPreference = 'Stop'

if (-not $env:AGORA_EMAIL -or -not $env:AGORA_IDENTITY_TOKEN) {
    Write-Host '::warning::Faltan AGORA_EMAIL / AGORA_IDENTITY_TOKEN. Se omite axe DevTools CLI.'
    exit 0
}

# Variables vacías (secretos no definidos) se tratan como "no definidas".
foreach ($v in 'AXE_DEVHUB_API_KEY', 'AXE_DEVHUB_PROJECT_ID') {
    if ([string]::IsNullOrWhiteSpace((Get-Item "env:$v" -ErrorAction SilentlyContinue).Value)) {
        Remove-Item "env:$v" -ErrorAction SilentlyContinue
    }
}

# 1) Configurar ~/.npmrc para el registro privado de Deque (Agora).
#    _auth = base64("<email>:<identity-token>")
$auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($env:AGORA_EMAIL):$($env:AGORA_IDENTITY_TOKEN)"))
$reg  = '//agora.dequecloud.com/artifactory/api/npm/devtools-npm/'
@(
    "@axe-devtools:registry=https:$reg",
    "${reg}:_auth=`"$auth`"",
    "${reg}:email=$($env:AGORA_EMAIL)",
    "${reg}:always-auth=true"
) | Set-Content -Path (Join-Path $HOME '.npmrc') -Encoding ascii

# 2) Instalar el CLI.
npm install -g '@axe-devtools/cli'
if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar @axe-devtools/cli (revisa credenciales de Agora).' }

# 3) Escanear.
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$server = & "$PSScriptRoot/Start-LocalServer.ps1" -Root './src' -Port $Port
try {
    foreach ($page in $Pages) {
        $url = "http://localhost:$Port/$page"
        Write-Host "axe DevTools CLI -> $url"
        # --save guarda JSON; --report genera HTML.
        axe $url "--save=$OutDir/devtools-$page.json" "--report=$OutDir/reports/"
        Write-Host "Código de salida: $LASTEXITCODE"
    }
}
finally {
    Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
}
