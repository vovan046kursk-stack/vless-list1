$urls = @(
"https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt"
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
