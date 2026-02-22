if (Test-Path "ip_port_pool.txt") {
    Remove-Item "ip_port_pool.txt"
}

$allowedPairs = @(
"146.185.240.23:443",
"79.137.175.44:443",
"87.239.110.251:443",
"84.23.52.70:443",
"158.160.197.213:443",
"158.160.223.36:443",
"95.163.211.158:8443",
"51.250.26.102:443"
"51.250.117.173:5443"
)

$allowedPairs | Set-Content ip_port_pool.txt -Encoding UTF8
