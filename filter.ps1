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

function Test-SingBox {
    param($line)

    try {
        # временный конфиг
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

        Start-Sleep -Seconds 3

        try {
            Invoke-WebRequest "https://1.1.1.1" -TimeoutSec 5 | Out-Null
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

foreach ($line in $lines) {

    if ($line -notmatch "^vless://") { continue }

    # фильтр IP
    if (
        $line -notmatch "@5\.188\." -and
        $line -notmatch "@109\.120\." 
    ) { continue }

    # порт
    if ($line -notmatch ":443") { continue }

    # домен
    if ($line -notmatch "x5\.ru") { continue }

    Write-Host "Проверка через sing-box..."

    if (Test-SingBox $line) {
        Write-Host "OK"
        $result += $line.Trim()
    }
    else {
        Write-Host "DEAD"
    }

    if ($result.Count -ge $maxResults) {
        Write-Host "Достигнуто 50"
        break
    }
}

$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
