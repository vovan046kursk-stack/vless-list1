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

$proxiesYaml = ""
$proxyNames = @()

$index = 1

foreach ($line in $vlessLines) {

    try {
        $uriPart = $line.Split("@")[1]
        $serverPort = $uriPart.Split("?")[0]
        $server = $serverPort.Split(":")[0]
        $port = $serverPort.Split(":")[1]

        $uuid = ($line -split "vless://")[1].Split("@")[0]

        $name = "$server-$port-$index"
        $proxyNames += $name

        $proxiesYaml += @"
  - name: "$name"
    type: vless
    server: $server
    port: $port
    uuid: $uuid
    network: tcp
    tls: true
    udp: true
"@

        $index++

    } catch {
        continue
    }
}

# Удаляем дубликаты
$proxyNames = $proxyNames | Sort-Object -Unique

# Формируем список для YAML
$autoList = ""
$proxyList = ""

foreach ($p in $proxyNames) {
    $autoList += "      - $p`n"
    $proxyList += "      - $p`n"
}

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
$proxiesYaml

proxy-groups:
  - name: Auto
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    tolerance: 50
    proxies:
$autoList

  - name: Proxy
    type: select
    proxies:
      - Auto
      - DIRECT
$proxyList

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
