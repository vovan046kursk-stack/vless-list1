$urls = @(
"https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/Vless-Reality-White-Lists-Rus-Mobile.txt",
"https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/WHITE-CIDR-RU-checked.txt",
"https://raw.githubusercontent.com/AvenCores/goida-vpn-configs/refs/heads/main/githubmirror/26.txt",
"https://white-lists.vercel.app/api/filter?code=ALL&type=white&min=false",
"https://raw.githubusercontent.com/EtoNeYaProject/etoneyaproject.github.io/refs/heads/main/1"
)

$out = "all_vless.txt"
$result = @()

foreach ($url in $urls) {
    try {
        Write-Host "Downloading $url"
        $content = Invoke-WebRequest -Uri $url -UseBasicParsing
        $lines = $content.Content -split "`n"
        $vless = $lines | Where-Object { $_ -match "^vless://" }
        $result += $vless
    }
    catch {
        Write-Host "Failed: $url"
    }
}

$result = $result | Sort-Object -Unique
$result | Set-Content $out -Encoding utf8NoBOM

Write-Host "Downloaded total:" $result.Count
