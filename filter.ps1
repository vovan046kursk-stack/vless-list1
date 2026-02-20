$inputFile  = "vless_list_new.txt"
$poolFile   = "ip_port_pool.txt"
$manualFile = "manual_ip_port.txt"
$outputFile = "filtered_vless.txt"

if (!(Test-Path $inputFile)) {
    Write-Host "vless_list_new.txt not found"
    exit 1
}

$vlessList = Get-Content $inputFile

# ===============================
# Загружаем авто IP
# ===============================
$ipPortList = @()

if (Test-Path $poolFile) {
    $ipPortList += Get-Content $poolFile
}

# ===============================
# Загружаем ручные IP (ВЕЧНЫЕ)
# ===============================
if (Test-Path $manualFile) {
    $manualIPs = Get-Content $manualFile
    $ipPortList += $manualIPs
}

# Убираем дубли
$ipPortList = $ipPortList | Sort-Object -Unique

if ($ipPortList.Count -eq 0) {
    Write-Host "No IP list"
    exit 1
}

$filtered = @()

# ===============================
# ФИЛЬТР VLESS ПО IP:PORT
# ===============================
foreach ($line in $vlessList) {

    if ($line -notmatch "^vless://") { continue }

    foreach ($ip in $ipPortList) {

        $parts = $ip.Split(":")
        if ($parts.Count -ne 2) { continue }

        $server = $parts[0]
        $port   = $parts[1]

        if ($line -match "@$server`:$port") {
            $filtered += $line
            break
        }
    }
}

# ===============================
# Удаляем дубли
# ===============================
$filtered = $filtered | Sort-Object -Unique

if ($filtered.Count -eq 0) {
    Write-Host "No matching VLESS"
    exit 1
}

# ===============================
# Сохраняем
# ===============================
$filtered | Out-File $outputFile -Encoding utf8

Write-Host "Filtered VLESS saved: $($filtered.Count)"
