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

    # 🔥 только нужные IP
    if (
        $line -notmatch "@5\.188\." -and
        $line -notmatch "@109\.120\."
    ) { continue }

    # 🔥 только порт 443
    if ($line -notmatch ":443") { continue }

    # 🔥 только ads.x5.ru
    if ($line -notmatch "ads\.x5\.ru") { continue }

    # 🔥 достаём IP
    if ($line -match "@([^:]+):443") {
        $ip = $matches[1]
    } else {
        continue
    }

    # 🔥 ключ (только IP, т.к. SNI одинаковый)
    $key = "$ip"

    if ($seen.ContainsKey($key)) {
        continue
    }

    $seen[$key] = $true
    $result += $line.Trim()
}

Write-Host "После фильтра:" $result.Count

$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
