$outputFile = "vless_list_new.txt"
$inputFile = "all_sources.txt"

Write-Host "Читаю $inputFile ..."

if (!(Test-Path $inputFile)) {
    Write-Host "Файл не найден!"
    exit 1
}

$lines = Get-Content $inputFile

$result = @()
$seen = @{}

foreach ($line in $lines) {

    if ($line -notmatch "^vless://") { continue }

    # 🔥 блокируем плохие IP
    if (
        $line -match "@51\.250\." -or
        $line -match "@84\.201\."
    ) { continue }

    # 🔥 порты
    if (
        $line -notmatch ":443" -and
        $line -notmatch ":8443" -and
        $line -notmatch ":6443" -and
        $line -notmatch ":8447"
    ) { continue }

    # 🔥 SNI фильтр
    if (
        $line -notmatch "ads\.x5\.ru" -and
        $line -notmatch "5post-gate\.x5\.ru" -and
        $line -notmatch "anti-vpn\.ru" -and
        $line -notmatch "x5\.ru" -and
        $line -notmatch "vkclip\.enotfast\.com" -and
        $line -notmatch "wl-3\.legendary-vpn\.com" -and
        $line -notmatch "botapi\.max\.ru"
    ) { continue }

    # 🔥 достаём IP и порт
    if ($line -match "@([^:]+):(\d+)") {
        $ip = $matches[1]
        $port = $matches[2]
    } else {
        continue
    }

    # 🔥 достаём SNI
    if ($line -match "sni=([^&]+)") {
        $sni = $matches[1]
    } else {
        $sni = "none"
    }

    # 🔥 ключ (IP + PORT + SNI)
    $key = "$ip|$port|$sni"

    if ($seen.ContainsKey($key)) {
        continue
    }

    $seen[$key] = $true
    $result += $line.Trim()
}

Write-Host "После фильтра:" $result.Count

$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
