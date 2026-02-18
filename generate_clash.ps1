# ==============================
# GENERATE CLASH CONFIG
# ==============================

$ErrorActionPreference = "Stop"

$inputFile = "filtered_vless.txt"
$outputFile = "clash_pool.yaml"

if (!(Test-Path $inputFile)) {
    Write-Host "filtered_vless.txt not found"
    exit 1
}

$lines = Get-Content $inputFile

$proxies = @()

foreach ($line in $lines) {

    if ($line -match "^vless://([^@]+)@([\d\.]+):(\d+)\?(.*)$") {

        $uuid = $matches[1]
        $server = $matches[2]
        $port = $matches[3]
        $params = $matches[4]

        $name = "$server-$port"

        $proxies += @"
  - name: "$name"
    type: vless
    server: $server
    port: $port
    uuid: $uuid
    network: tcp
    tls: true
    flow: xtls-rprx-vision
"@
    }
}

$proxyBlock = $proxies -join "`n"

$config = @"
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info

proxies:
$proxyBlock

proxy-groups:
  - name: Auto
    type: url-test
    url: https://www.gstatic.com/generate_204
    interval: 300
    proxies:
$(($proxies | ForEach-Object { ($_ -split '"')[1] } | ForEach-Object { "      - $_" }) -join "`n")

  - name: Fallback
    type: fallback
    url: https://www.gstatic.com/generate_204
    interval: 300
    proxies:
$(($proxies | ForEach-Object { ($_ -split '"')[1] } | ForEach-Object { "      - $_" }) -join "`n")

  - name: Proxy
    type: select
    proxies:
      - Auto
      - Fallback
$(($proxies | ForEach-Object { ($_ -split '"')[1] } | ForEach-Object { "      - $_" }) -join "`n")

rules:
  # Cloudflare safe
  - DOMAIN-KEYWORD,yaplakal,DIRECT
  - DOMAIN-SUFFIX,yaplakal.com,DIRECT

  # Through proxy
  - DOMAIN-SUFFIX,nnmclub.to,Proxy
  - DOMAIN-SUFFIX,vipdrive.net,Proxy
  - DOMAIN-SUFFIX,4pda.to,Proxy
  - DOMAIN-SUFFIX,filmix.my,Proxy

  # Local networks
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT

  - MATCH,DIRECT
"@

$config | Set-Content $outputFile -Encoding UTF8

Write-Host "Clash config generated"
