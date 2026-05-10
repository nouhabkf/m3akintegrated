# Démarre l’app Flutter (mobile par défaut ; ajoute -Web pour le navigateur)
param(
    [switch]$Web
)
$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $PSScriptRoot
# Code Flutter à jour (communauté, vision, TTS) : frontend\appm3ak\appm3ak
$app = Join-Path $racine 'frontend\appm3ak\appm3ak'
Set-Location $app
Write-Host "Flutter : $app" -ForegroundColor Cyan
flutter pub get
if ($Web) {
    flutter run -d chrome
} else {
    flutter run
}
