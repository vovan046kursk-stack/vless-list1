if (Test-Path "ip_port_pool.txt") {
    Remove-Item "ip_port_pool.txt"
}

$ips = @()

Get-Content all_vless.txt | ForEach-Object {

    if ($_ -match '@([\d\.]+:\d+)') {

        $ip = $matches[1]

        if ($ips -notcontains $ip) {
            $ips += $ip
        }
    }
}

$ips | Set-Content ip_port_pool.txt -Encoding UTF8
