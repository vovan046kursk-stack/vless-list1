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

    # 🔥 только порт 443
    if ($line -notmatch ":443") { continue }

    # 🔥 SNI фильтр (добавили anti-vpn.ru)
    if (
        $line -notmatch "ads\.x5\.ru" -and
        $line -notmatch "5post-gate\.x5\.ru" -and
        $line -notmatch "x5\.ru" -and
        $line -notmatch "anti-vpn\.ru"
    ) { continue }

    # 🔥 достаём IP
    if ($line -match "@([^:]+):443") {
        $ip = $matches[1]
    } else {
        continue
    }

    # 🔥 достаём SNI
    if ($line -match "sni=([^&]+)") {
        $sni = $matches[1]
    } else {
        $sni = "none"
    }

    # 🔥 ключ (IP + SNI)
    $key = "$ip|$sni"

    if ($seen.ContainsKey($key)) {
        continue
    }

    $seen[$key] = $true
    $result += $line.Trim()
}

Write-Host "После фильтра:" $result.Count

$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
