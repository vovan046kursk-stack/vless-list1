$inputFile = "filtered_vless.txt"
$outputFile = "clash_pool.yaml"

if (!(Test-Path $inputFile)) {
    Write-Host "filtered_vless.txt not found"
    exit 1
}

$vlessLines = Get-Content $inputFile | Where-Object { $_ -match "^vless://" }

if ($vlessLines.Count -eq 0) {
    Write-Host "No VLESS entries found"
    exit 1
}

$proxies = @()
$proxyNames = @()

foreach ($line in $vlessLines) {

    try {
        $uuid = ($line -split "vless://")[1].Split("@")[0]
        $rest = $line.Split("@")[1]
        $serverPort = $rest.Split("?")[0]

        $server = $serverPort.Split(":")[0]
        $port = $serverPort.Split(":")[1]

        $name = "$server-$port"

        if ($proxyNames -contains $name) { continue }

        $proxyNames += $name

        $proxies += @{
            name = $name
            type = "vless"
            server = $server
            port = [int]$port
            uuid = $uuid
            network = "tcp"
            tls = $true
            udp = $true
        }

    } catch {
        continue
    }
}

# Формируем YAML вручную (без ошибок отступов)

$yaml = @"
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info

dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

proxies:
"@

foreach ($p in $proxies) {
$yaml += @"
  - name: "$($p.name)"
    type: vless
    server: $($p.server)
    port: $($p.port)
    uuid: $($p.uuid)
    network: tcp
    tls: true
    udp: true

"@
}

$yaml += @"
proxy-groups:
  - name: Auto
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    tolerance: 50
    proxies:
"@

foreach ($name in $proxyNames) {
    $yaml += "      - $name`n"
}

$yaml += @"

  - name: Proxy
    type: select
    proxies:
      - Auto
      - DIRECT
"@

foreach ($name in $proxyNames) {
    $yaml += "      - $name`n"
}

$yaml += @"

rules:
  - DOMAIN-KEYWORD,yaplakal,DIRECT
  - DOMAIN-SUFFIX,yaplakal.com,DIRECT
  - DOMAIN-SUFFIX,yaplakal.net,DIRECT

  - DOMAIN-SUFFIX,nnmclub.to,Proxy
  - DOMAIN-SUFFIX,vipdrive.net,Proxy
  - DOMAIN-SUFFIX,4pda.to,Proxy
  - DOMAIN-SUFFIX,filmix.my,Proxy

  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT

  - MATCH,DIRECT
"@

$yaml | Set-Content $outputFile -Encoding UTF8

Write-Host "clash_pool.yaml generated successfully"
