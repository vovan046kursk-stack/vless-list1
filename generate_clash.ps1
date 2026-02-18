$input = "vless_list_new.txt"
$output = "clash_pool.yaml"

if (!(Test-Path $input)) {
    Write-Host "vless_list_new.txt not found"
    exit 1
}

$result = @()

$result += "mixed-port: 7890"
$result += "allow-lan: false"
$result += "mode: rule"
$result += "log-level: info"
$result += ""

$result += "proxies:"

foreach ($line in Get-Content $input) {

    if ($line -match "^vless://([^@]+)@([^:]+):(\d+)\?(.*)#?(.*)") {

        $uuid = $matches[1]
        $server = $matches[2]
        $port = $matches[3]
        $params = $matches[4]
        $name = $matches[5]

        if ($name -eq "") {
            $name = "$server-$port"
        }

        $pbk = ""
        $sid = ""
        $sni = ""

        if ($params -match "pbk=([^&]+)") { $pbk = $matches[1] }
        if ($params -match "sid=([^&]+)") { $sid = $matches[1] }
        if ($params -match "sni=([^&]+)") { $sni = $matches[1] }

        $result += "  - name: `"$name`""
        $result += "    type: vless"
        $result += "    server: $server"
        $result += "    port: $port"
        $result += "    uuid: $uuid"
        $result += "    network: tcp"
        $result += "    tls: true"
        $result += "    servername: $sni"
        $result += "    reality-opts:"
        $result += "      public-key: $pbk"
        $result += "      short-id: $sid"
        $result += "    flow: xtls-rprx-vision"
        $result += ""
    }
}

$result += ""
$result += "proxy-groups:"
$result += "  - name: Proxy"
$result += "    type: select"
$result += "    proxies:"
$result += "      - Auto"
$result += "      - Fallback"
$result += "      - Manual"
$result += "      - DIRECT"
$result += ""

$result += "  - name: Auto"
$result += "    type: url-test"
$result += "    url: https://www.gstatic.com/generate_204"
$result += "    interval: 300"
$result += "    use:"
$result += "      - pool"
$result += ""

$result += "  - name: Fallback"
$result += "    type: fallback"
$result += "    url: https://www.gstatic.com/generate_204"
$result += "    interval: 300"
$result += "    use:"
$result += "      - pool"
$result += ""

$result += "  - name: Manual"
$result += "    type: select"
$result += "    use:"
$result += "      - pool"
$result += ""

$result += "rules:"
$result += "  - DOMAIN-KEYWORD,yaplakal,DIRECT"
$result += "  - DOMAIN-SUFFIX,yaplakal.com,DIRECT"
$result += "  - DOMAIN-SUFFIX,yaplakal.net,DIRECT"
$result += ""
$result += "  - DOMAIN-SUFFIX,nnmclub.to,Proxy"
$result += "  - DOMAIN-SUFFIX,api.sponsor.ajay.app,Proxy"
$result += "  - DOMAIN-SUFFIX,vipdrive.net,Proxy"
$result += "  - DOMAIN-SUFFIX,4pda.to,Proxy"
$result += "  - DOMAIN-SUFFIX,filmix.my,Proxy"
$result += ""
$result += "  - IP-CIDR,127.0.0.0/8,DIRECT"
$result += "  - IP-CIDR,10.0.0.0/8,DIRECT"
$result += "  - IP-CIDR,172.16.0.0/12,DIRECT"
$result += "  - IP-CIDR,192.168.0.0/16,DIRECT"
$result += ""
$result += "  - MATCH,DIRECT"

$result | Set-Content $output -Encoding utf8

Write-Host "clash_pool.yaml generated"
