$inputFile = "all_sources.txt"
$outputFiltered = "filtered_vless.txt"
$outputFinal = "vless_list_new.txt"
$stateFile = "server_state.json"

# ===== ЖЁСТКИЙ WHITELIST =====
$allowed = @(
"79.137.175.44:443",
"87.239.110.251:443",
"95.163.211.158:8443",
"51.250.26.102:443",
"37.139.32.112:8443",
"37.139.34.165:8443",
"37.139.33.15:8443",
"37.139.35.12:8443",
"37.139.34.145:8443",
"84.23.53.243:443",
"178.250.243.188:3443"
)

# ===== Проверка входного файла =====
if (!(Test-Path $inputFile)) {
    Write-Host "all_sources.txt not found"
    exit 1
}

# ===== Загрузка состояния =====
if (Test-Path $stateFile) {
    $json = Get-Content $stateFile -Raw | ConvertFrom-Json
    $state = @{}
    foreach ($prop in $json.PSObject.Properties) {
        $state[$prop.Name] = $prop.Value
    }
}
else {
    $state = @{}
}

# ===== Читаем VLESS =====
$vlessLines = Get-Content $inputFile | Where-Object { $_ -match "^vless://" }

$seen = @{}
$alive = @()

foreach ($line in $vlessLines) {

    if ($line -match "vless://.*@([^:]+):(\d+)") {

        $ip = $matches[1]
        $port = $matches[2]
        $key = "$ip`:$port"

        # --- ЖЁСТКАЯ проверка whitelist ---
        if (-not ($allowed -contains $key)) {
            continue
        }

        # --- Удаление дублей ---
        if ($seen.ContainsKey($key)) {
            continue
        }

        $seen[$key] = $true

        # ===== TCP проверка =====
        try {
            $tcp = Test-NetConnection -ComputerName $ip -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        }
        catch {
            $tcp = $false
        }

        # ===== Ping =====
        try {
            $pingResult = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
            $pingOk = $pingResult -ne $null
            $latency = if ($pingOk) { $pingResult.ResponseTime } else { 9999 }
        }
        catch {
            $pingOk = $false
            $latency = 9999
        }

        if ($tcp -and $pingOk) {

            # сервер жив → сброс счётчика
            $state[$key] = 0

            $alive += [PSCustomObject]@{
                Key = $key
                Line = $line
                Latency = $latency
            }

            Write-Host "$key ALIVE ($latency ms)"
        }
        else {

            # сервер мёртв → увеличиваем счётчик
            if ($state.ContainsKey($key)) {
                $state[$key] += 1
            }
            else {
                $state[$key] = 1
            }

            Write-Host "$key DEAD count: $($state[$key])"
        }
    }
}

# ===== Исключение после 2 падений =====
$final = @()

foreach ($item in $alive) {

    $key = $item.Key

    if ($state[$key] -lt 2) {
        $final += $item
    }
}

# ===== Сортировка по задержке =====
$sorted = $final | Sort-Object Latency

# ===== Запись файлов =====
$sorted.Line | Set-Content $outputFiltered
$sorted.Line | Set-Content $outputFinal

# ===== Сохранение состояния =====
$state | ConvertTo-Json | Set-Content $stateFile

Write-Host ""
Write-Host "FINAL SERVERS:" $sorted.Count
