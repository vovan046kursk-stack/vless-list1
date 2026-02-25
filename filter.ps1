# ==============================
# ENTERPRISE VLESS FILTER
# ==============================

$inputFile      = "all_sources.txt"
$outputFiltered = "filtered_vless.txt"
$outputFinal    = "vless_list_new.txt"
$stateFile      = "state.json"

# ===== ЖЁСТКИЙ WHITELIST =====
$allowed = @{
"79.137.175." = @("443")
"95.163.211." = @("443")
"212.233.98." = @("8443")
"212.233.123." = @("8443")
}

# ===== Настройки =====
$quarantineLimit = 3
$deleteLimit     = 5
$topLimit        = 5

if (!(Test-Path $inputFile)) {
    Write-Host "Input file not found"
    exit 1
}

# ===== Загрузка состояния =====
if (Test-Path $stateFile) {
    $raw = Get-Content $stateFile -Raw | ConvertFrom-Json
    $state = @{}
    foreach ($p in $raw.PSObject.Properties) {
        $state[$p.Name] = $p.Value
    }
}
else {
    $state = @{}
}

$vlessLines = Get-Content $inputFile | Where-Object { $_ -match "^vless://" }

$alive = @()
$seen  = @{}

foreach ($line in $vlessLines) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]
        $key  = "$ip`:$port"

        # whitelist
        if (-not ($allowed -contains $key)) { continue }

        # убрать дубли
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        if (-not $state.ContainsKey($key)) {
            $state[$key] = @{
                fail = 0
                quarantine = $false
            }
        }

        # ===== TCP CHECK =====
        try {
            $tcp = Test-NetConnection -ComputerName $ip -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        }
        catch {
            $tcp = $false
        }

        if ($tcp) {

            $state[$key].fail = 0
            $state[$key].quarantine = $false

            # latency через TCP
            try {
                $ping = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
                $lat  = if ($ping) { $ping.ResponseTime } else { 9999 }
            }
            catch {
                $lat = 9999
            }

            $alive += [PSCustomObject]@{
                Key = $key
                Line = $line
                Latency = $lat
            }

            Write-Host "$key ALIVE ($lat ms)"
        }
        else {

            $state[$key].fail++

            if ($state[$key].fail -ge $deleteLimit) {
                Write-Host "$key REMOVED after $deleteLimit fails"
                continue
            }

            if ($state[$key].fail -ge $quarantineLimit) {
                $state[$key].quarantine = $true
                Write-Host "$key QUARANTINE ($($state[$key].fail))"
            }
            else {
                Write-Host "$key FAIL ($($state[$key].fail))"
            }
        }
    }
}

# ===== Убираем карантин =====
$finalAlive = $alive | Where-Object {
    -not $state[$_.Key].quarantine
}

# ===== Сортировка по latency =====
$sorted = $finalAlive | Sort-Object Latency

# ===== TOP + RESERVE =====
$top     = $sorted | Select-Object -First $topLimit
$reserve = $sorted | Select-Object -Skip $topLimit

$top.Line | Set-Content $outputFinal -Encoding utf8
$sorted.Line | Set-Content $outputFiltered -Encoding utf8

# ===== Сохранение состояния =====
$state | ConvertTo-Json -Depth 3 | Set-Content $stateFile

Write-Host ""
Write-Host "TOP SERVERS:" $top.Count
Write-Host "RESERVE:" $reserve.Count


