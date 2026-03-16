# ==========================================
# FILTER1 - DEBUG VERSION (REALITY + VISION)
# Output: vless_list_new.txt
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

# ===== PREFIX + PORT WHITELIST =====
$allowed = @{
"212.233."      = @("443","8443")
"87.239."       = @("443","8443")
"89.208."       = @("443","8443")
"90.156."       = @("52006")
"84.201."       = @("443")
"84.23."        = @("443")
"37.139."       = @("443")
"5.188."        = @("443")
"185.254."      = @("443")
"185.241."      = @("8443")
"185.40."        = @("443")
"109.120."      = @("443")
"51.250."       = @("443","7445","8443")
"91.219."       = @("9443")
"95.163."       = @("443","8443")
"146.185."     = @("443","3443")
"78.41."       = @("443")
"79.137."   = @("443","8443","51102")
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
$final = $result | Select-Object -First 100
$final | Set-Content $outputFile

Write-Host "Final count saved:" $final.Count
Write-Host "Done. Saved to $outputFile"
