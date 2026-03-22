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

    # 🔥 IP фильтр
    if (
        $line -notmatch "@5\.188\." -and
        $line -notmatch "@109\.120\." -and
        $line -notmatch "@95\.163\." -and
        $line -notmatch "@89\.208\."
    ) { continue }

    # порт 443
    if ($line -notmatch ":443") { continue }

    # SNI фильтр
    if (
        $line -notmatch "ads\.x5\.ru" -and
        $line -notmatch "5post-gate\.x5\.ru" -and
        $line -notmatch "x5\.ru"
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

    # если уже есть — пропускаем
    if ($seen.ContainsKey($key)) {
        continue
    }

    $seen[$key] = $true
    $result += $line.Trim()
}

Write-Host "После удаления дублей:" $result.Count

# сохраняем
$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
