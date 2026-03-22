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

# 🔥 проверка через HTTPS (YouTube)
function Test-YouTube {
    param($ip)

    try {
        $request = [System.Net.HttpWebRequest]::Create("https://youtube.com")
        $request.Timeout = 3000
        $request.Host = "youtube.com"

        # подключаемся к IP
        $request.ServicePoint.BindIPEndPointDelegate = {
            param($servicePoint, $remoteEndPoint, $retryCount)
            return New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Parse($ip), 0)
        }

        $response = $request.GetResponse()
        $response.Close()
        return $true
    }
    catch {
        return $false
    }
}

foreach ($line in $lines) {

    if ($line -notmatch "^vless://") { continue }

    # IP фильтр
    if (
        $line -notmatch "@5\.188\." -and
        $line -notmatch "@109\.120\." -and
        $line -notmatch "@37\.139\." -and
        $line -notmatch "@95\.163\."
    ) { continue }

    # порт 443
    if ($line -notmatch ":443") { continue }

    # x5.ru
    if ($line -notmatch "x5\.ru") { continue }

    # достаём IP
    if ($line -match "@([^:]+):443") {
        $ip = $matches[1]

        Write-Host "Проверка YouTube $ip..."

        if (Test-YouTube $ip) {
            Write-Host "OK $ip"
            $result += $line.Trim()
        }
        else {
            Write-Host "DEAD $ip"
        }

        if ($result.Count -ge $maxResults) {
            Write-Host "Достигнуто 50 адресов"
            break
        }
    }
}

Write-Host "`nЖивых:" $result.Count

$result | Out-File -Encoding utf8 $outputFile

Write-Host "Готово → $outputFile"
