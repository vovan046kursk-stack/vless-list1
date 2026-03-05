# ==========================================
# VLESS SCANNER 4.1 (GitHub optimized)
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

$scoreFile = "ip_scores.txt"
$cooldownFile = "cooldown_ips.txt"

$cooldownTime = 3600
$tcpTimeout = 700

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

# ===== LOAD SCORE =====

$scores = @{}
if (Test-Path $scoreFile) {
    Get-Content $scoreFile | ForEach-Object {
        $p = $_ -split ","
        if ($p.Count -eq 2) {
            $scores[$p[0]] = [int]$p[1]
        }
    }
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

# ===== LOAD SOURCES =====

$lines = Get-Content $inputFile

# ===== PARAM FILTER =====

$filtered = $lines | Where-Object {

    $_ -match "^vless://" -and
    $_ -match "security=reality" -and
    $_ -match "flow=xtls-rprx-vision"

}

Write-Host "Reality lines:" $filtered.Count

# ===== PREFIX FILTER =====

$targets = @()

foreach ($line in $filtered) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip = $matches[1]
        $port = $matches[2]

        if ($cooldown.ContainsKey($ip)) {

            if (($now - $cooldown[$ip]) -lt $cooldownTime) {
                continue
            }

        }

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

# ===== TCP CHECK =====

$alive = @()

foreach ($t in $targets) {

    $ip = $t.ip
    $port = $t.port
    $line = $t.line

    try {

        $tcp = New-Object System.Net.Sockets.TcpClient
        $task = $tcp.ConnectAsync($ip,$port)

        if ($task.Wait($tcpTimeout) -and $tcp.Connected) {

            $alive += $line

            if ($scores.ContainsKey($ip)) {
                $scores[$ip] += 3
            } else {
                $scores[$ip] = 3
            }

        }
        else {

            $cooldown[$ip] = $now

        }

        $tcp.Close()

    }
    catch {}

}

Write-Host "TCP alive:" $alive.Count

# ===== RANKING =====

$ranked = $alive | Sort-Object {

    if ($_ -match "@([^:]+):") {

        $ip = $matches[1]

        if ($scores.ContainsKey($ip)) {
            $scores[$ip]
        } else {0}

    }

} -Descending

# ===== OUTPUT =====

$final = $ranked | Select-Object -First 40

$final | Set-Content $outputFile

# ===== SAVE SCORE =====

$scores.GetEnumerator() | ForEach-Object {
    "$($_.Key),$($_.Value)"
} | Set-Content $scoreFile

# ===== SAVE COOLDOWN =====

$cooldown.GetEnumerator() | ForEach-Object {
    "$($_.Key),$($_.Value)"
} | Set-Content $cooldownFile

Write-Host "Final servers:" $final.Count
$task = $tcp.ConnectAsync($ip,$port)

if ($task.Wait(1500)) {

if ($tcp.Connected) {

$alive.Add($line)

}

}

$tcp.Close()

} catch {}

} -ThrottleLimit $threads

Write-Host "TCP alive:" $alive.Count

# ===== UPDATE SCORE =====

foreach ($line in $alive) {

if ($line -match "@([^:]+):") {

$ip = $matches[1]

if ($scores.ContainsKey($ip)) {

$scores[$ip] += 3

} else {

$scores[$ip] = 3

}

}

}

# ===== RANK =====

$ranked = $alive | Sort-Object {

if ($_ -match "@([^:]+):") {

$ip = $matches[1]

if ($scores.ContainsKey($ip)) {

$scores[$ip]

} else {0}

}

} -Descending

# ===== OUTPUT =====

$final = $ranked | Select-Object -First 40

$final | Set-Content $outputFile

# ===== SAVE SCORE =====

$scores.GetEnumerator() | ForEach-Object {

"$($_.Key),$($_.Value)"

} | Set-Content $scoreFile

# ===== SAVE COOLDOWN =====

$cooldown.GetEnumerator() | ForEach-Object {

"$($_.Key),$($_.Value)"

} | Set-Content $cooldownFile

Write-Host "Final servers:" $final.Count
