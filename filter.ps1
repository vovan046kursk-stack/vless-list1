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

    if (
        
        $line -match "@5\.42\."
    ) { continue }

    # =========================
    # ✅ ПОРТЫ (быстрее regex)
    # =========================

    if ($line -notmatch ":(9999|6445|666|8443|5444|8080|2053|9443|443|7443|6443)") {
        continue
    }

    # =========================
    # ✅ SNI ФИЛЬТР
    # =========================

    if ($line -notmatch "(5ka-cdn\.x5static\.net|ads\.x5\.ru|www\.philips\.com|ads\.x5media\.ru|5post-gate\.x5\.ru|x5\.ru|5post-gate-test\.ru|max\.ru|ru-portal\.meetvideo\.ru|web\.max\.ru|www\.vk\.com|yandex\.ru|api-maps\.yandex\.ru|mc\.yandex\.ru)") {
        continue
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
    # ❌ ДУБЛИ (умнее)
    # =========================

    $key = "$ip|$port|$sni"

    if ($seen.ContainsKey($key)) { continue }

    $seen[$key] = $true
    $result += $line
}

# =========================
# СОХРАНЕНИЕ
# =========================

Write-Host "🔥 После фильтра:" $result.Count

$result | Out-File -Encoding utf8 $outputFile

Write-Host "✅ Готово → $outputFile"
