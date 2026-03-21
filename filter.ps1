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

    if ($line -notmatch "^vless://") { continue }

    # IP фильтр
    if ($line -notmatch "@5\.188\." -and $line -notmatch "@109\.120\.") { continue }

    # порт 443
    if ($line -notmatch ":443") { continue }

    # x5.ru
    if ($line -notmatch "x5\.ru") { continue }

    # 👇 дубликаты сохраняем
    $result += $line.Trim()
}

Write-Host "Найдено:" $result.Count

# сохраняем
$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
