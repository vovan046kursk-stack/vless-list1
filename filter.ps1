# ==============================
# FILTER VLESS (GitHub version)
# ==============================

$ErrorActionPreference = "Stop"

# Источники подписок
$sources = @(
"https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt",
"https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/Vless-Reality-White-Lists-Rus-Mobile.txt",
"https://raw.githubusercontent.com/vsevjik/OBSpiskov/refs/heads/main/wwh_old"
)

# Разрешённые порты
$allowedPorts = @("443","8443","6443","7443","9443","51102")

$outputFile = "filtered_vless.txt"

Write-Host "Downloading sources..."

$allLines = @()

foreach ($url in $sources) {
    try {
        $content = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
        $allLines += $content.Content -split "`n"
        Write-Host "Downloaded: $url"
    }
    catch {
        Write-Host "Failed: $url"
    }
}

Write-Host "Filtering..."

$result = @()

foreach ($line in $allLines) {

    if ($line -match "^vless://") {

        if ($line -match "@([\d\.]+):(\d+)") {

            $port = $matches[2]

            if ($allowedPorts -contains $port) {
                $result += $line.Trim()
            }
        }
    }
}

$result = $result | Sort-Object -Unique

$result | Set-Content $outputFile -Encoding UTF8

Write-Host "Saved $($result.Count) entries to $outputFile"
