$output = "vless_list_new.txt"

$allowed = Get-Content "ip_port_pool.txt"

$urls = @(
"https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt",
"https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/Vless-Reality-White-Lists-Rus-Mobile.txt",
"https://raw.githubusercontent.com/vsevjik/OBSpiskov/refs/heads/main/wwh_old"
)

$result = @()

foreach ($url in $urls) {

    Write-Host "Downloading $url"

    try {
        $content = Invoke-WebRequest -Uri $url -UseBasicParsing
        $lines = $content.Content -split "`n"

        foreach ($line in $lines) {

            if ($line -notlike "vless://*") { continue }

            if ($line -match "@([\d\.]+):(\d+)") {

                $pair = "${($matches[1])}:${($matches[2])}"

                if ($allowed -contains $pair) {
                    $result += $line.Trim()
                }
            }
        }
    }
    catch {
        Write-Host "Failed $url"
    }
}

$result |
    Sort-Object -Unique |
    Set-Content $output -Encoding utf8

Write-Host "DONE"
