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
        $line -match "@84\.23\." -or
        $line -match "@62\.152\." -or
        $line -match "@147\.45\." -or
        $line -match "@158\.160\." -or
        $line -match "@51\.250\." -or
        $line -match "@84\.201\."
    ) { continue }

    # 🔥 порты
    if (
        $line -notmatch ":5444" -and
        $line -notmatch ":8080" -and
        $line -notmatch ":9443" -and
        $line -notmatch ":443" -and
        $line -notmatch ":7443" -and
        $line -notmatch ":6443" -and
        $line -notmatch ":8443"
    ) { continue }

    # 🔥 SNI фильтр
    if (
    $line -notmatch "5ka-cdn\.x5static\.net" -and
    $line -notmatch "ads\.x5\.ru" -and
    $line -notmatch "ads\.x5media\.ru" -and
    $line -notmatch "5post-gate\.x5\.ru" -and
    $line -notmatch "x5\.ru" -and
    $line -notmatch "5post-gate-test\.ru" -and
    $line -notmatch "max\.ru" -and
    $line -notmatch "ru-portal\.meetvideo\.ru" -and
    $line -notmatch "web\.max\.ru" -and
    $line -notmatch "vkvideo\.ru" -and
    $line -notmatch "www\.vk\.com"
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
