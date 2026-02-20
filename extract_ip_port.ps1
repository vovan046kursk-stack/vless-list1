if (Test-Path "ip_port_pool.txt") {
    Remove-Item "ip_port_pool.txt"
}

$allowedPairs = @(
"109.120.190.78:443",
"109.120.191.46:443",
"5.188.143.111:443"
)

$allowedPairs | Set-Content ip_port_pool.txt -Encoding UTF8
