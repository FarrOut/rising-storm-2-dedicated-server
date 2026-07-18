# ============================================================
# Build the RS2 Vietnam server image.
# Prompts for Steam credentials securely — nothing is written
# to disk or stored in the image.
# ============================================================

$env:STEAM_USER = Read-Host "Steam username"
$env:STEAM_PASS = Read-Host "Steam password" -AsSecureString | `
    ForEach-Object { [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($_)) }
$env:STEAM_GUARD = Read-Host "Steam Guard code (from mobile app)"

Write-Host "`nBuilding image — this will take a while..." -ForegroundColor Cyan

docker build `
    --secret id=steam_user,env=STEAM_USER `
    --secret id=steam_pass,env=STEAM_PASS `
    --secret id=steam_guard,env=STEAM_GUARD `
    -t rs2vietnam-server:latest `
    (Split-Path $PSScriptRoot -Leaf)

# Clear credentials from environment immediately after build
Remove-Item Env:STEAM_USER -ErrorAction SilentlyContinue
Remove-Item Env:STEAM_PASS -ErrorAction SilentlyContinue
Remove-Item Env:STEAM_GUARD -ErrorAction SilentlyContinue

Write-Host "Done. Credentials cleared from environment." -ForegroundColor Green
