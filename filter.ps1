$outputFile = "vless_list_new.txt"
$inputFile = "all_sources.txt"
$maxResults = 50

Write-Host "Читаю $inputFile ..."

if (!(Test-Path $inputFile)) {
    Write-Host "Файл не найден!"
    exit 1
}

$lines = Get-Content $inputFile

$result = @()

# 🔥 функция оценки
function Get-Score($line) {
    $score = 0

    if ($line -match "ads\.x5\.ru") { $score += 5 }
    elseif ($line -match "5post-gate\.x5\.ru") { $score += 4 }
    elseif ($line -match "x5\.ru") { $score += 2 }

    if ($line -match "@5\.188\.") { $score += 3 }
    elseif ($line -match "@95\.163\.") { $score += 3 }
    elseif ($line -match "@109\.120\.") { $score += 2 }
    elseif ($line -match "@37\.139\.") { $score += 2 }

    return $score
}

# 🔥 проверка через sing-box (упрощённая)
function Test-SingBox {
    param($line)

    try {
        $config = @{
            "log" = @{ "disabled" = $true }
            "outbounds" = @(
                @{
                    "type" = "vless"
                    "tag" = "test"
                    "server" = ($line -replace '.*@([^:]+):.*','$1')
                    "server_port" = 443
                    "uuid" = ($line -replace 'vless://([^@]+)@.*','$1')
                    "flow" = "xtls-rprx-vision"
                    "tls" = @{
                        "enabled" = $true
                        "server_name" = "ads.x5.ru"
                        "insecure" = $true
                    }
                }
            )
        }

        $config | ConvertTo-Json -Depth 10 | Out-File test.json

        $proc = Start-Process "./sing-box" -ArgumentList "run -c test.json" -PassThru

        Start-Sleep -Seconds 2

        try {
            Invoke-WebRequest "https://1.1.1.1" -TimeoutSec 3 | Out-Null
            $ok = $true
        }
        catch {
            $ok = $false
        }

        Stop-Process $proc -ErrorAction Ignore
        return $ok
    }
    catch {
        return $false
    }
}

Write-Host "Фильтрация..."

$filtered = @()

foreach ($line in $lines) {

    if ($line -notmatch "^vless://") { continue }

    if (
        $line -notmatch "@5\.188\." -and
        $line -notmatch "@109\.120\." -and
        $line -notmatch "@37\.139\." -and
        $line -notmatch "@95\.163\."
    ) { continue }

    if ($line -notmatch ":443") { continue }

    if ($line -notmatch "x5\.ru") { continue }

    $score = Get-Score $line

    $filtered += [PSCustomObject]@{
        line = $line.Trim()
        score = $score
    }
}

Write-Host "После фильтра:" $filtered.Count

# 🔥 сортировка по качеству
$filtered = $filtered | Sort-Object score -Descending

Write-Host "Проверка через sing-box..."

foreach ($item in $filtered) {

    Write-Host "Score $($item.score)"

    if (Test-SingBox $item.line) {
        Write-Host "OK"
        $result += $item.line
    } else {
        Write-Host "DEAD"
    }

    if ($result.Count -ge $maxResults) {
        break
    }
}

Write-Host "Итог:" $result.Count

$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
