# =========================
# НАСТРОЙКИ
# =========================

$sourceUrl = "https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt"

$outputFile = "vless_list_new.txt"
$inputFile  = "all_sources.txt"

# =========================
# СКАЧИВАНИЕ (если файла нет)
# =========================

if (!(Test-Path $inputFile)) {
    Write-Host "📥 Файл не найден, скачиваю..."

    try {
        $resp = Invoke-WebRequest -Uri $sourceUrl -UseBasicParsing
        $content = $resp.Content.Trim()

        # base64 decode если нужно
        if ($content -match "^[A-Za-z0-9+/=\r\n]+$") {
            try {
                $bytes = [System.Convert]::FromBase64String($content)
                $content = [System.Text.Encoding]::UTF8.GetString($bytes)
                Write-Host "🔐 base64 декодировано"
            } catch {}
        }

        $content | Out-File -Encoding utf8 $inputFile
        Write-Host "✅ Сохранён → $inputFile"
    }
    catch {
        Write-Host "❌ Ошибка скачивания!"
        exit 1
    }
}

# =========================
# ЧТЕНИЕ
# =========================

Write-Host "📖 Читаю $inputFile ..."

$lines = Get-Content $inputFile

$result = @()
$seen = @{}

foreach ($line in $lines) {

    $line = $line.Trim()

    if ($line -notmatch "^vless://") { continue }

    # =========================
    # ❌ ПЛОХИЕ IP
    # =========================

    if ($line -match "@5\.42\.") { continue }

    # =========================
    # ✅ ПОРТЫ
    # =========================

    if ($line -notmatch ":(|9999|5446|2448|6445|8454|8443|5444|8080|2053|9443|443|7443|6443)") {
        continue
    }

    # =========================
    # ✅ SNI ФИЛЬТР
    # =========================

  if ($line -notmatch '(5ka-cdn\.x5static\.net|ads\.x5\.ru|ads\.x5media\.ru|5post-gate\.x5\.ru|5post-gate-test\.ru|x5\.ru|max\.ru|web\.max\.ru|ru-portal\.meetvideo\.ru|www\.vk\.com|sun6-\d+\.userapi\.com|yandex\.ru|api-maps\.yandex\.ru|mc\.yandex\.ru|www\.philips\.com|wl-\d+-\d+\.legendary-vpn\.com|tunnel\.vk-apps\.com|megafon\.ru|vkvideo\.ru|sweden\.nosok-top\.com|ger\.nosok-top\.com|m\.ok\.ru|jobinvest\.ru|quiz\.kinopoisk\.ru)') {
    }

    # =========================
    # 📦 ПАРСИНГ
    # =========================

    if ($line -match "@([^:]+):(\d+)") {
        $ip = $matches[1]
        $port = $matches[2]
    } else { continue }

    if ($line -match "sni=([^&]+)") {
        $sni = $matches[1]
    } else {
        $sni = "none"
    }

    # =========================
    # ❌ ДУБЛИ
    # =========================

    $key = "$ip|$port|$sni"

    if ($seen.ContainsKey($key)) { continue }

    $seen[$key] = $true
    $result += $line
}

# =========================
# СОХРАНЕНИЕ
# =========================

$result = $result | Select-Object -First 50

Write-Host "🔥 После фильтра:" $result.Count

$result | Out-File -Encoding utf8 $outputFile

Write-Host "✅ Готово → $outputFile"

