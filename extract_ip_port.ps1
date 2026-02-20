if (Test-Path "ip_port_pool.txt") {
    Remove-Item "ip_port_pool.txt"
}

$allowedPairs = @(
"51.250.0.147:443",
"158.160.221.132:443",
"130.193.59.133:443"
)

$allowedPairs | Set-Content ip_port_pool.txt -Encoding UTF8
