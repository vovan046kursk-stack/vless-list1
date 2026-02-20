$sourceFile = "all_sources.txt"
$poolFile   = "ip_port_pool.txt"
$outputFile = "vless_list_new.txt"

$allowed = Get-Content $poolFile | ForEach-Object {
    ($_ -replace "\s","").Trim()
}

$result = @()

Get-Content $sourceFile | Where-Object { $_ -match "^vless://" } | ForEach-Object {

    if ($_ -match "@([^:]+):(\d+)") {

        $ip   = $Matches[1]
        $port = $Matches[2]
        $pair = "$ip`:$port"

        if ($allowed -contains $pair) {
            $result += $_
        }
    }
}

$result = $result | Sort-Object -Unique
$result | Out-File $outputFile -Encoding utf8

Write-Host "Saved:" $result.Count

