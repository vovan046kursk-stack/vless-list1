# ==========================================
# FILTER1 - DEBUG VERSION (REALITY + VISION)
# Output: vless_list_new.txt
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

# ===== PREFIX + PORT WHITELIST =====
$allowed = @{
    "212.233.98."  = @("8443")
    "212.233.123." = @("8443")
    "212.233.121." = @("8443")
    "212.233.120." = @("8443")
    "87.239.108."  = @("8443")
    "87.239.107."  = @("443")
    "89.208.222."  = @("8443")
    "84.201.128."  = @("443")
    "84.201.173."  = @("443")
    "84.23.52."    = @("443")
    "84.23.53."    = @("443")
    "37.139.33."   = @("443")
    "5.188.140."   = @("443")
    "185.254.98."  = @("443")
    "185.241.193." = @("8443")
    "185.40.152." = @("443")
    "109.120.188." = @("443")
    "109.120.189." = @("443")
    "51.250.20."   = @("8443")
    "51.250.4."    = @("443")
    "51.250.103."   = @("443")
    "91.219.227."   = @("9443")
    "95.163.183."  = @("443")
    "95.163.208."  = @("443")
    "95.163.210."  = @("443","8443")
    "146.185.240."  = @("443")
    "78.41.109."    = @("443")
    "79.137.175."  = @("8443","51102","443")
}

# ===== START =====
if (!(Test-Path $inputFile)) {
    Write-Host "Input file not found!"
    exit 1
}

$lines = Get-Content $inputFile
Write-Host "Total lines:" $lines.Count

# ===== PARAM FILTER =====
$filtered = $lines | Where-Object {
    $_ -match "^vless://" -and
    $_ -match "security=reality" -and
    $_ -match "flow=xtls-rprx-vision"
}

Write-Host "After param filter:" $filtered.Count

# ===== MAIN FILTER =====
$unique = @{}
$result = @()

foreach ($line in $filtered) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]

        $allowedMatch = $false

        foreach ($prefix in $allowed.Keys) {
            if ($ip.StartsWith($prefix) -and $allowed[$prefix] -contains $port) {
                $allowedMatch = $true
                break
            }
        }

        if (-not $allowedMatch) { continue }

        # Remove duplicates by IP
        if (-not $unique.ContainsKey($ip)) {
            $unique[$ip] = $true
            $result += $line
        }
    }
}

Write-Host "After whitelist:" $result.Count

# ===== LIMIT OUTPUT =====
$final = $result | Select-Object -First 50
$final | Set-Content $outputFile

Write-Host "Final count saved:" $final.Count
Write-Host "Done. Saved to $outputFile"
