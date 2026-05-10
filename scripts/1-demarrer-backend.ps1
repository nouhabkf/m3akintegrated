# Démarre l’API NestJS (garder ce terminal ouvert)
$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $racine 'backend\backend-m3ak 2'
Set-Location $backend
Write-Host "Backend : $backend" -ForegroundColor Cyan
npm run start:dev
