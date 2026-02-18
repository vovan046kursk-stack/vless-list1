# ===== INPUT / OUTPUT =====
$inputFile  = "filtered_vless.txt"
$outputFile = "clash_pool.yaml"

if (!(Test-Path $inputFile)) {
    Write-Host "filtered_vless.txt not found"
    exit 1
}

# ===== PARSE VLESS =====
$proxies = @()
$proxyNames = @()

foreach ($line in Get-Content $inputFile) {

    if ($line -notmatch "^vless://") { continue }

    if ($line -match "vless://([^@]+)@([^:]+):(\d+)\?(.*)#?(.*)") {

        $uuid  = $matches[1]
        $server = $matches[2]
        $port  = $matches[3]
        $params = $matches[4]

        $name = "$server-$port"
        $proxyNames += $name

        # defaults
        $tls = "false"
        $servername = ""
        $flow = ""
        $publicKey = ""
        $shortId = ""
        $network = "tcp"

        if ($params -match "security=tls") { $tls = "true" }
        if ($params -match "security=reality") { $tls = "true" }

        if ($params -match "sni=([^&]+)") {
            $servername = $matches[1]
        }

        if ($params -match "flow=([^&]+)") {
            $flow = $matches[1]
        }

        if ($params -match "pbk=([^&]+)") {
            $publicKey = $matches[1]
        }

        if ($params -match "sid=([^&]+)") {
            $shortId = $matches[1]
        }

        if ($params -match "type=ws") {
            $network = "ws"
        }

        $proxyBlock = @"
  - name: "$name"
    type: vless
    server: $server
    port: $port
    uuid: $uuid
    network: $network
    tls: $tls
"@

        if ($servername -ne "") {
            $proxyBlock += "    servername: $servername`n"
        }

        if ($flow -ne "") {
            $proxyBlock += "    flow: $flow`n"
        }

        if ($publicKey -ne "") {
            $proxyBlock += @"
    reality-opts:
      public-key: $publicKey
      short-id: $shortId
"@
        }

        $proxies += $proxyBlock
    }
}

if ($proxyNames.Count -eq 0) {
    Write-Host "No proxies parsed"
    exit 1
}

# ===== BUILD YAML =====

$yaml = @"
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info

proxies:
"@

foreach ($p in $proxies) {
    $yaml += "$p`n"
}

# ===== PROXY GROUPS =====

$yaml += @"
proxy-groups:

  - name: Auto
    type: url-test
    url: https://www.gstatic.com/generate_204
    interval: 300
    proxies:
"@

foreach ($n in $proxyNames) {
    $yaml += "      - `"$n`"`n"
}

$yaml += @"

  - name: Fallback
    type: fallback
    url: https://www.gstatic.com/generate_204
    interval: 300
    proxies:
"@

foreach ($n in $proxyNames) {
    $yaml += "      - `"$n`"`n"
}

$yaml += @"

  - name: Manual
    type: select
    proxies:
"@

foreach ($n in $proxyNames) {
    $yaml += "      - `"$n`"`n"
}

$yaml += @"
      - DIRECT

  - name: Proxy
    type: select
    proxies:
      - Auto
      - Fallback
      - Manual
      - DIRECT

rules:

  # Cloudflare safe
  - DOMAIN-KEYWORD,yaplakal,DIRECT
  - DOMAIN-SUFFIX,yaplakal.com,DIRECT
  - DOMAIN-SUFFIX,yaplakal.net,DIRECT

  # proxy sites
  - DOMAIN-SUFFIX,nnmclub.to,Proxy
  - DOMAIN-SUFFIX,vipdrive.net,Proxy
  - DOMAIN-SUFFIX,4pda.to,Proxy
  - DOMAIN-SUFFIX,filmix.my,Proxy

  # local networks
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT

  - MATCH,DIRECT
"@

# ===== SAVE =====
$yaml | Set-Content $outputFile -Encoding UTF8

Write-Host "clash_pool.yaml generated successfully"
