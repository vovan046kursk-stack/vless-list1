$outputFile = "vless_list_new.txt"
$inputFile = "all_sources.txt"
$maxResults = 50  # Максимальное количество живых адресов

Write-Host "Читаю $inputFile ..."

# Проверка, что файл существует
if (!(Test-Path $inputFile)) {
    Write-Host "Файл $inputFile не найден!"
    exit 1
}

$lines = Get-Content $inputFile

$result = @()

# 🔥 Функция проверки TCP
function Test-Port {
    param($ip, $port)

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($ip, $port, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne(1500, $false)

        if ($success -and $client.Connected) {
            $client.EndConnect($iar)
            $client.Close()
            return $true
        }

        $client.Close()
        return $false
    }
    catch {
        return $false
    }
}

# Процесс фильтрации
foreach ($line in $lines) {

    if ($line -notmatch "^vless://") { continue }

    # Фильтруем по IP (5.188.*, 109.120.*, 37.139.*, 95.163.*)
    if (
        $line -notmatch "@5\.188\." -and
        $line -notmatch "@109\.120\."
       
    ) { continue }

    # Порт 443
    if ($line -notmatch ":443") { continue }

    # x5.ru
    if ($line -notmatch "x5\.ru") { continue }

    # Извлекаем IP
    if ($line -match "@([^:]+):443") {
        $ip = $matches[1]

        Write-Host "Проверка $ip..."

        # Проверка TCP (порт 443)
        if (Test-Port $ip 443) {
            Write-Host "OK $ip"
            $result += $line.Trim()
        }
        else {
            Write-Host "DEAD $ip"
        }

        # Если найдено 50 живых адресов, останавливаем процесс
        if ($result.Count -ge $maxResults) {
            Write-Host "Достигнуто максимальное количество живых адресов: $maxResults"
            break
        }
    }
}

Write-Host "`nЖивых:" $result.Count

# Сохраняем результат в файл
$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
