# ==========================================
# VLESS FILTER (GitHub optimized)
# Whitelist + Dedup + Limit
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

# ===== PREFIX WHITELIST =====

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

# ===== LOAD SOURCES =====

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

# ===== PREFIX FILTER =====

$targets = @()

foreach ($line in $filtered) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]

        foreach ($prefix in $allowed.Keys) {

            if ($ip.StartsWith($prefix) -and $allowed[$prefix] -contains $port) {

                $targets += [PSCustomObject]@{
                    ip=$ip
                    port=$port
                    line=$line
                }

                break
            }

        }

    }

}

Write-Host "Targets before dedup:" $targets.Count

# ===== REMOVE DUPLICATES =====

$targets = $targets | Sort-Object ip,port -Unique

Write-Host "Targets after dedup:" $targets.Count

# ===== LIMIT SERVERS =====

$final = $targets | Select-Object -First 40

# ===== SAVE OUTPUT =====

$final | ForEach-Object { $_.line } | Set-Content $outputFile

Write-Host "Final servers:" $final.Count
Write-Host "Saved to $outputFile"
