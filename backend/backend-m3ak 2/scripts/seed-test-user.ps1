# Cree le compte de test (Windows). API doit tourner : npm run start:dev
# Ouvrir un terminal dans le backend, ex. :
#   cd "C:\Users\DELL\Downloads\backend-m3ak\backend-m3ak 2"
#   npm run start:dev
$uri = "http://localhost:3000/user/register"
$body = @{
  nom          = "Test"
  prenom       = "Dev"
  email        = "ma3akdev@example.com"
  password     = "Test123!"
  telephone    = "+21600000000"
  role         = "HANDICAPE"
  typeHandicap = "VISUEL"
} | ConvertTo-Json

Write-Host "POST $uri"
Write-Host "Body: $body"
try {
  $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json; charset=utf-8"
  Write-Host "OK - compte cree ou reponse:" 
  $response | ConvertTo-Json
} catch {
  $status = $_.Exception.Response.StatusCode.value__
  $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
  $text = $reader.ReadToEnd()
  Write-Host "Erreur $status"
  Write-Host $text
}
