if (Test-Path "ip_port_pool.txt") {
    Remove-Item "ip_port_pool.txt"
}

$allowedPairs = @(
"51.250.0.147:443",
"109.120.191.46:443",
"84.23.52.70:443"
)

$allowedPairs | Set-Content ip_port_pool.txt -Encoding UTF8
