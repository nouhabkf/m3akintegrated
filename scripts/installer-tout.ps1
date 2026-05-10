# Installation des dépendances — projet unifié Ma3ak
$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $racine 'backend\backend-m3ak 2'
$flutter = Join-Path $racine 'frontend\appm3ak\appm3ak'

Write-Host '=== npm install (backend) ===' -ForegroundColor Cyan
Set-Location $backend
npm install

Write-Host '=== flutter pub get (app) ===' -ForegroundColor Cyan
Set-Location $flutter
flutter pub get

Write-Host 'Terminé. Lance ensuite 1-demarrer-backend.ps1 puis 2-demarrer-flutter.ps1' -ForegroundColor Green
