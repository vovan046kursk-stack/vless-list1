$inputFile = "all_sources.txt"
$outputFiltered = "filtered_vless.txt"
$outputFinal = "vless_list_new.txt"
$stateFile = "server_state.json"

# ===== ТВОЙ whitelist =====
$allowed = @(
"146.185.240.23:443",
"79.137.175.44:443",
"87.239.110.251:443",
"84.201.129.41:8443",
"158.160.197.213:443",
"158.160.223.36:443",
"95.163.211.158:8443",
"51.250.26.102:443",
"212.233.95.129:4443"
)

# ===== Загружаем состояние =====
if (Test-Path $stateFile) {
    $state = Get-Content $stateFile | ConvertFrom-Json
} else {
    $state = @{}
}

$vlessLines = Get-Content $inputFile | Where-Object { $_ -match "^vless://" }

$seen = @{}
$alive = @()

foreach ($line in $vlessLines) {

    if ($line -match "vless://.*@([^:]+):(\d+)") {

        $ip = $matches[1]
        $port = $matches[2]
        $key = "$ip`:$port"

        if (($allowed -contains $key) -and (-not $seen.ContainsKey($key))) {

            $seen[$key] = $true

            # TCP CHECK
            try {
                $tcp = Test-NetConnection -ComputerName $ip -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
            } catch { $tcp = $false }

            if ($tcp) {

                # сервер жив → сброс счетчика
                $state.$key = 0

                $latency = (Test-Connection -ComputerName $ip -Count 1).ResponseTime

                $alive += [PSCustomObject]@{
                    Line = $line
                    Latency = $latency
                }
            }
            else {

                # сервер мертв → увеличиваем счетчик
                if ($state.$key) {
                    $state.$key += 1
                } else {
                    $state.$key = 1
                }

                Write-Host "$key dead count: $($state.$key)"
            }
        }
    }
}

# ===== Удаляем тех, кто умер 2 раза =====
$alive = $alive | Where-Object {
    $k = ($_ .Line -match "@([^:]+):(\d+)"; "$($matches[1]):$($matches[2])")
    $state.$k -lt 2
}

# сортируем по ping
$sorted = $alive | Sort-Object Latency

$sorted.Line | Set-Content $outputFiltered
$sorted.Line | Set-Content $outputFinal

# сохраняем состояние
$state | ConvertTo-Json | Set-Content $stateFile

Write-Host "Alive servers:" $sorted.Count

