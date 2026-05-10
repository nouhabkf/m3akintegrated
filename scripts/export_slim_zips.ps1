# Export frontend.zip + backend.zip sans module Santé, taille cible < 25 Mo chacun.
# Usage: depuis la racine du dépôt (appm3ak):  powershell -ExecutionPolicy Bypass -File scripts/export_slim_zips.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Staging = Join-Path $RepoRoot "_slim_zip_staging"
$FeSrc = Join-Path $RepoRoot "frontend\appm3ak\appm3ak"
$BeSrc = Join-Path $RepoRoot "backend\backend-m3ak 2"

if (-not (Test-Path $FeSrc)) { throw "Dossier frontend introuvable: $FeSrc" }
if (-not (Test-Path $BeSrc)) { throw "Dossier backend introuvable: $BeSrc" }

Remove-Item $Staging -Recurse -Force -ErrorAction SilentlyContinue
$FeOut = Join-Path $Staging "frontend"
$BeOut = Join-Path $Staging "backend"
New-Item -ItemType Directory -Path $FeOut -Force | Out-Null
New-Item -ItemType Directory -Path $BeOut -Force | Out-Null

Write-Host "Copie Flutter (exclusion build, .dart_tool, etc.)..."
$excludeDirs = @(
  ".dart_tool", "build", ".git", "linux", "macos", "windows", "test"
)
robocopy $FeSrc $FeOut /E /NFL /NDL /NJH /NJS /XD $excludeDirs | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy frontend a echoue: $LASTEXITCODE" }

Write-Host "Copie backend (sans node_modules, dist)..."
robocopy $BeSrc $BeOut /E /NFL /NDL /NJH /NJS /XD node_modules dist coverage .git | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy backend a echoue: $LASTEXITCODE" }

# --- Suppressions lourdes / sante (frontend) ---
$toRemove = @(
  (Join-Path $FeOut "lib\features\health"),
  (Join-Path $FeOut "lib\features\medical"),
  (Join-Path $FeOut "lib\providers\health_providers.dart"),
  (Join-Path $FeOut "assets\models"),
  (Join-Path $FeOut "assets\videos\gestures")
)
foreach ($p in $toRemove) {
  if (Test-Path $p) {
    Remove-Item $p -Recurse -Force
    Write-Host "Supprime: $p"
  }
}

# Fichiers de remplacement (router + shell sans sante)
Copy-Item (Join-Path $PSScriptRoot "slim-export\app_router.dart") (Join-Path $FeOut "lib\router\app_router.dart") -Force
Copy-Item (Join-Path $PSScriptRoot "slim-export\main_shell.dart") (Join-Path $FeOut "lib\features\home\screens\main_shell.dart") -Force

# Profil: retirer tuile Dossier medical (regex, espaces variables)
$profilePath = Join-Path $FeOut "lib\features\profile\screens\profile_tab.dart"
if (Test-Path $profilePath) {
  $pt = Get-Content $profilePath -Raw -Encoding UTF8
  $pt2 = $pt -replace '(?s)if \(user\.isBeneficiary\) \.\.\.\[.*?\],', ''
  Set-Content $profilePath $pt2 -Encoding UTF8 -NoNewline
}

# pubspec: retirer assets models / videos si absents
$pub = Join-Path $FeOut "pubspec.yaml"
if (Test-Path $pub) {
  $py = Get-Content $pub -Raw -Encoding UTF8
  $py = $py -replace "(?m)^\s*-\s*assets/models/\s*\r?\n", ""
  $py = $py -replace "(?m)^\s*-\s*assets/videos/\s*\r?\n", ""
  Set-Content $pub $py -Encoding UTF8 -NoNewline
}

# README export
@"
Export léger Ma3ak (sans module Santé / dossier médical / gros modèles ML).
- Sources Flutter + backend Nest sans node_modules.
- Restaurer le dépôt complet depuis Git pour le module Santé.
"@ | Set-Content (Join-Path $FeOut "LISEZMOI_EXPORT.txt") -Encoding UTF8

# Zip
$outDir = $RepoRoot
$feZip = Join-Path $outDir "frontend.zip"
$beZip = Join-Path $outDir "backend.zip"
if (Test-Path $feZip) { Remove-Item $feZip -Force }
if (Test-Path $beZip) { Remove-Item $beZip -Force }

Compress-Archive -LiteralPath $FeOut -DestinationPath $feZip -Force
Compress-Archive -LiteralPath $BeOut -DestinationPath $beZip -Force

$mbFe = [math]::Round((Get-Item $feZip).Length / 1MB, 2)
$mbBe = [math]::Round((Get-Item $beZip).Length / 1MB, 2)
Write-Host ""
Write-Host "OK: $feZip  ($mbFe Mo)"
Write-Host "OK: $beZip  ($mbBe Mo)"
if ($mbFe -ge 25 -or $mbBe -ge 25) {
  Write-Warning "Un ZIP depasse 25 Mo: reduire android/assets ou autres dossiers lourds."
}
Remove-Item $Staging -Recurse -Force
Write-Host "Termine."
