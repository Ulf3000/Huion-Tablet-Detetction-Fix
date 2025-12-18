#Requires -RunAsAdministrator

Start-Sleep -Seconds 2

# === CONFIG ===
# Your Huion hub when healthy:
$GOOD_HUB_PREFIX = "USB\VID_1A40&PID_0101"
# Your failed placeholder:
$BAD_PREFIX      = "USB\VID_0000&PID_0002"

# Port anchor (from your instance id: ...&0&14). Keep exactly this tail.
$PORT_TAIL       = "&0&13"

# Force this inbox driver:
$INF = "$env:WINDIR\INF\usbhub3.inf"

# Huion UI to start afterwards:
$HUION_UI = "C:\Program Files\HuionTablet\HuionTablet.exe"

# DevCon next to this script:
$DEVCON = Join-Path $PSScriptRoot "devcon.exe"

# === HELPERS ===
function Find-HuionHubOnPort {
    Get-PnpDevice -PresentOnly | Where-Object {
        ($_.InstanceId -like "$GOOD_HUB_PREFIX*${PORT_TAIL}" -or $_.InstanceId -like "$BAD_PREFIX*${PORT_TAIL}")
    } | Select-Object -First 1
}

# === MAIN ===
if (!(Test-Path $DEVCON)) {
    Write-Host "[ERR] devcon.exe not found next to script: $DEVCON"
    Write-Host "      Put devcon.exe in the same folder and rerun."
    exit 2
}
if (!(Test-Path $INF)) {
    Write-Host "[ERR] Missing INF: $INF"
    exit 3
}else {
    Write-Host   "INf found"

}

$dev = Find-HuionHubOnPort
if (!$dev) {
    Write-Host "[ERR] No Huion hub device found on the anchored port tail '$PORT_TAIL'."
    exit 4
}else {
    Write-Host   "Device found!!!!!!!!!!!!!!!!"
}

Write-Host "[INFO] Found device:"
Write-Host "       $($dev.FriendlyName)"
Write-Host "       $($dev.InstanceId)"
Write-Host "       Status: $($dev.Status)"

$needsFix = ($dev.InstanceId -like "$BAD_PREFIX*") -or ($dev.Status -ne "OK")

if ($needsFix) {
    Write-Host "[FIX] Forcing Generic SuperSpeed Hub driver (usbhub3.inf) on this device instance..."

    # IMPORTANT: '@' tells devcon this is a DEVICE INSTANCE ID (not HWID)
    & $DEVCON UpdateNI $INF "@$($dev.InstanceId)" | Out-Host

    Start-Sleep -Seconds 2

    Write-Host "[FIX] Restarting device..."
    & pnputil /restart-device "$($dev.InstanceId)" | Out-Null

    Start-Sleep -Seconds 2
} else {
    Write-Host "[OK] Device already healthy; skipping driver force."
}

Write-Host "[INFO] Starting HuionTablet.exe..."
if (Test-Path $HUION_UI) {
    Start-Process $HUION_UI
} else {
    Write-Host "[WARN] HuionTablet.exe not found at: $HUION_UI"
}

Write-Host "[DONE]"
