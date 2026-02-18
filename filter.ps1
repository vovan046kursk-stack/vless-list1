$allowed = @(
"37.139.33.52:443",
"37.139.33.15:443",
"109.120.188.140:443",
"178.250.243.100:443",
"178.250.243.220:443",
"37.139.34.237:443",
"89.208.228.250:8443",
"178.250.243.208:443",
"178.250.243.222:443",
"178.250.243.221:443",
"178.250.243.211:443",
"178.250.243.99:443",
"178.250.243.210:443",
"51.250.73.139:8443",
"5.188.143.8:443",
"151.101.37.194:443",
"84.23.52.70:8443",
"5.188.143.8:8443",
"81.200.151.139:443",
"95.163.208.52:443",
"46.243.235.109:443",
"84.201.128.76:443",
"151.236.114.162:6443",
"188.253.17.225:443",
"109.120.189.137:9443",
"158.160.105.121:8443",
"79.137.175.59:8443",
"37.139.33.57:443",
"5.188.140.18:1488",
"109.120.191.92:1488",
"151.236.114.233:6443"
)

$urls = @(
"https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt",
"https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/Vless-Reality-White-Lists-Rus-Mobile.txt",
"https://raw.githubusercontent.com/vsevjik/OBSpiskov/refs/heads/main/wwh_old"
)

$temp = "all_sources.txt"
$output = "filtered_vless.txt"

Remove-Item $temp -ErrorAction SilentlyContinue
Remove-Item $output -ErrorAction SilentlyContinue

foreach ($url in $urls) {
    try {
        Invoke-WebRequest $url -OutFile "$temp.tmp"
        Get-Content "$temp.tmp" | Add-Content $temp
        Remove-Item "$temp.tmp"
    } catch {}
}

if (!(Test-Path $temp)) {
    Write-Host "No sources downloaded"
    exit 1
}

$result = @()

Get-Content $temp | ForEach-Object {
    if ($_ -match "^vless://" -and $_ -match "@([\d\.]+):(\d+)") {
        $ipport = "$($matches[1]):$($matches[2])"
        if ($allowed -contains $ipport) {
            $result += $_.Trim()
        }
    }
}

$result = $result | Sort-Object -Unique
$result | Set-Content $output -Encoding UTF8

Write-Host "Final whitelist count: $($result.Count)"
