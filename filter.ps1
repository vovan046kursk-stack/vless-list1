# ==========================================
# VLESS REALITY FILTER (FULL OPTIMIZED)
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"
$historyFile = "subnet_history.json"

# ===== STATIC WHITELIST =====

$allowed = @{

"212.233." = @("8443")
"87.239." = @("443","8443")
"89.208.222." = @("8443")
"84.201." = @("443")
"84.23." = @("443")
"37.139.33." = @("443")
"5.188.140." = @("443")
"185.254.98." = @("443")
"185.241.193." = @("8443")
"185.40.152." = @("443")
"109.120." = @("443")
"51.250." = @("443","8443")
"91.219.227." = @("9443")
"95.163." = @("443","8443")
"146.185.240." = @("443")
"78.41.109." = @("443")
"79.137.175." = @("443","8443","51102")

}

# ===== LOAD HISTORY =====

if (Test-Path $historyFile) {
    $history = Get-Content $historyFile | ConvertFrom-Json
} else {
    $history = @{}
}

if (Test-Path $historyFile) {

    $json = Get-Content $historyFile -Raw | ConvertFrom-Json

    $history = @{}

    foreach ($p in $json.PSObject.Properties) {
        $history[$p.Name] = $p.Value
    }

}
else {

    $history = @{}

}

$lines = Get-Content $inputFile

Write-Host "Total lines:" $lines.Count

# ===== REALITY FILTER =====

$filtered = $lines | Where-Object {

    $_ -match "^vless://" -and
    $_ -match "security=reality" -and
    $_ -match "flow=xtls-rprx-vision"

}

Write-Host "After param filter:" $filtered.Count

$targets = @()

foreach ($line in $filtered) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]

        $prefix = ($ip.Split(".")[0..1] -join ".") + "."

        if ($allowed.ContainsKey($prefix) -and $allowed[$prefix] -contains $port) {

            $targets += [PSCustomObject]@{
                ip=$ip
                port=$port
                line=$line
            }

        }

        # ===== SUBNET HISTORY =====

        $parts = $ip.Split(".")
        $subnet = "$($parts[0]).$($parts[1]).$($parts[2])."

        if ($history.ContainsKey($subnet)) {
            $history[$subnet] += 1
        } else {
            $history[$subnet] = 1
        }

    }

}

Write-Host "Targets before dedup:" $targets.Count

# ===== REMOVE DUPLICATES =====

$targets = $targets | Sort-Object ip,port -Unique

Write-Host "Targets after dedup:" $targets.Count

# ===== SMART SUBNET FILTER =====

$bestSubnets = $history.GetEnumerator() |
    Sort-Object Value -Descending |
    Select-Object -First 20 |
    ForEach-Object { $_.Key }

$targets = $targets | Where-Object {

    $parts = $_.ip.Split(".")
    $subnet = "$($parts[0]).$($parts[1]).$($parts[2])."

    $bestSubnets -contains $subnet

}

Write-Host "After subnet optimization:" $targets.Count

# ===== LIMIT BEFORE RTT =====

$targets = $targets | Select-Object -First 80

Write-Host "Targets for RTT test:" $targets.Count

# ===== PARALLEL TCP LATENCY TEST =====

$results = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

$targets | ForEach-Object -Parallel {

    try {

        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        $tcp = New-Object System.Net.Sockets.TcpClient
        $task = $tcp.ConnectAsync($_.ip,$_.port)

        if ($task.Wait(800)) {

            $sw.Stop()
            $latency = $sw.ElapsedMilliseconds

        }
        else {

            $latency = 999

        }

        $tcp.Close()

    }
    catch {

        $latency = 999

    }

    $results.Add([PSCustomObject]@{
        ip=$_.ip
        port=$_.port
        line=$_.line
        rtt=$latency
    })

} -ThrottleLimit 10

Write-Host "TCP latency test done"

# ===== SORT BY LATENCY =====

$sorted = $results | Sort-Object rtt

# ===== FINAL SERVERS =====

$final = $sorted | Select-Object -First 40

$final | ForEach-Object { $_.line } | Set-Content $outputFile

Write-Host "Saved servers:" $final.Count

# ===== LIMIT HISTORY =====

$maxSubnets = 40

$sortedHistory = $history.GetEnumerator() |
    Sort-Object Value -Descending |
    Select-Object -First $maxSubnets

$newHistory = @{}

foreach ($s in $sortedHistory) {
    $newHistory[$s.Key] = $s.Value
}

$newHistory | ConvertTo-Json | Set-Content $historyFile

Write-Host "Subnet history updated"
