# ==========================================
# FILTER ENTERPRISE VERSION (REALITY + VISION)
# Output: vless_list_new.txt
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

# ===== COOLDOWN SETTINGS =====
$cooldownFile = "cooldown_ips.txt"
$cooldownTime = 3600   # seconds (1 hour)

# ===== PREFIX + PORT WHITELIST =====
$allowed = @{
"212.233."      = @("8443")
"87.239."       = @("443","8443")
"89.208.222."   = @("8443")
"84.201."       = @("443")
"84.23."        = @("443")
"37.139.33."    = @("443")
"5.188.140."    = @("443")
"185.254.98."   = @("443")
"185.241.193."  = @("8443")
"185.40.152."   = @("443")
"109.120."      = @("443")
"51.250."       = @("443","8443")
"91.219.227."   = @("9443")
"95.163."       = @("443","8443")
"146.185.240."  = @("443")
"78.41.109."    = @("443")
"79.137.175."   = @("443","8443","51102")
}

# ===== LOAD COOLDOWN =====
$cooldown = @{}
if (Test-Path $cooldownFile) {
    Get-Content $cooldownFile | ForEach-Object {
        $p = $_ -split ","
        if ($p.Count -eq 2) {
            $cooldown[$p[0]] = [int]$p[1]
        }
    }
}

$now = [int][double]::Parse((Get-Date -UFormat %s))

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

        # ===== COOLDOWN CHECK =====
        if ($cooldown.ContainsKey($ip)) {
            if (($now - $cooldown[$ip]) -lt $cooldownTime) {
                continue
            }
        }

        # ===== PREFIX FILTER =====
        $allowedMatch = $false

        foreach ($prefix in $allowed.Keys) {
            if ($ip.StartsWith($prefix) -and $allowed[$prefix] -contains $port) {
                $allowedMatch = $true
                break
            }
        }

        if (-not $allowedMatch) {
            $cooldown[$ip] = $now
            continue
        }

        # ===== REMOVE DUPLICATES =====
        if (-not $unique.ContainsKey($ip)) {
            $unique[$ip] = $true
            $result += $line
        }
    }
}

Write-Host "After whitelist:" $result.Count

# ===== LIMIT OUTPUT =====
$final = $result | Select-Object -First 40

# ===== SAVE OUTPUT =====
$final | Set-Content $outputFile

# ===== SAVE COOLDOWN =====
$cooldown.GetEnumerator() | ForEach-Object {
    "$($_.Key),$($_.Value)"
} | Set-Content $cooldownFile

Write-Host "Final count saved:" $final.Count
Write-Host "Cooldown list size:" $cooldown.Count
Write-Host "Done. Saved to $outputFile"
