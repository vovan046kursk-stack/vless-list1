# ==========================================
# GITHUB CI VLESS FILTER (PREFIX + PORT)
# Output: vless_list_new.txt
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

# ===== PREFIX + PORT WHITELIST =====
$allowed = @{
    "79.137.175."  = @("443")
    "212.233.98."  = @("8443")
    "212.233.123." = @("8443")
    "89.208.222."  = @("8443")
    "95.163.210."  = @("443")
    "95.163.211."  = @("443")
    "109.120."     = @("443")
    "217.16."      = @("443")
    "51.250."      = @("443")
    "84.252."      = @("443")
}

if (!(Test-Path $inputFile)) {
    Write-Host "Input file not found!"
    exit 1
}

$lines = Get-Content $inputFile

# ===== PARAM FILTER =====
$filtered = $lines | Where-Object {
    $_ -match "^vless://" -and
    $_ -match "security=reality" -and
    $_ -match "flow=xtls-rprx-vision" -and
    $_ -match "type=tcp" -and
    $_ -match "fp=chrome"
}

# ===== PREFIX + PORT FILTER =====
$whitelisted = foreach ($line in $filtered) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]

        foreach ($prefix in $allowed.Keys) {
            if ($ip.StartsWith($prefix) -and $allowed[$prefix] -contains $port) {
                $line
                break
            }
        }
    }
}

# ===== REMOVE DUPLICATE IP =====
$unique = @{}
$result = foreach ($line in $whitelisted) {

    if ($line -match "@([^:]+):") {
        $ip = $matches[1]

        if (-not $unique.ContainsKey($ip)) {
            $unique[$ip] = $true
            $line
        }
    }
}

# ===== LIMIT =====
$final = $result | Select-Object -First 50

$final | Set-Content $outputFile

Write-Host "Done. Saved to $outputFile"
