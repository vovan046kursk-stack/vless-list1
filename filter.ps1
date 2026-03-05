# ==========================================
# VLESS REALITY FILTER
# Dynamic subnet + RTT sorting
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

if (!(Test-Path $inputFile)) {
    Write-Host "No sources"
    exit
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

        # subnet history

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

# ===== RTT TEST =====

$results = @()

foreach ($t in $targets) {

    try {

        $ping = Test-Connection -ComputerName $t.ip -Count 1 -TimeoutSeconds 1 -ErrorAction Stop

        $rtt = $ping.ResponseTime

        $results += [PSCustomObject]@{
            ip=$t.ip
            port=$t.port
            line=$t.line
            rtt=$rtt
        }

    }
    catch {

        $results += [PSCustomObject]@{
            ip=$t.ip
            port=$t.port
            line=$t.line
            rtt=999
        }

    }

}

Write-Host "RTT test done"

# ===== SORT BY LATENCY =====

$sorted = $results | Sort-Object rtt

# ===== TOP SERVERS =====

$final = $sorted | Select-Object -First 40

$final | ForEach-Object { $_.line } | Set-Content $outputFile

Write-Host "Saved servers:" $final.Count

# ===== LIMIT SUBNET HISTORY =====

$maxSubnets = 40

$sortedHistory = $history.GetEnumerator() | Sort-Object Value -Descending

$newHistory = @{}

$sortedHistory | Select-Object -First $maxSubnets | ForEach-Object {

    $newHistory[$_.Key] = $_.Value

}

$newHistory | ConvertTo-Json | Set-Content $historyFile

Write-Host "Subnet history saved"

Write-Host "Final servers:" $final.Count
Write-Host "Saved to $outputFile"
