$outputFile = "vless_list_new.txt"
$inputFile = "all_sources.txt"

Write-Host "Читаю $inputFile ..."

if (!(Test-Path $inputFile)) {
    Write-Host "Файл не найден!"
    exit 1
}

$lines = Get-Content $inputFile

$result = @()

foreach ($line in $lines) {

    # только VLESS
    if ($line -notmatch "^vless://") { continue }

    # 🔥 IP фильтр (топ под РФ)
    if (
        $line -notmatch "@5\.188\." -and
        $line -notmatch "@109\.120\." -and
        $line -notmatch "@95\.163\." -and
        $line -notmatch "@37\.139\."
    ) { continue }

    # 🔥 только порт 443
    if ($line -notmatch ":443") { continue }

    # 🔥 нормальные домены (без мусора)
    if (
        $line -notmatch "ads\.x5\.ru" -and
        $line -notmatch "5post-gate\.x5\.ru" -and
        $line -notmatch "x5\.ru"
    ) { continue }

    # 👇 дубликаты оставляем как есть
    $result += $line.Trim()
}

Write-Host "Найдено:" $result.Count

# сохраняем
$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
