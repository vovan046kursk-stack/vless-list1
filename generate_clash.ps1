$inputFile = "filtered_vless.txt"
$outputFile = "clash_pool.yaml"

if (!(Test-Path $inputFile)) {
    Write-Host "filtered_vless.txt not found"
    exit 1
}

$vlessLines = Get-Content $inputFile | Where-Object { $_ -match "^vless://" }

if ($vlessLines.Count -eq 0) {
    Write-Host "No VLESS links found"
    exit 1
}

$yaml = ""
$proxyNames = @()

# ---------- HEADER ----------
$yaml += "mixed-port: 7890`n"
$yaml += "allow-lan: false`n"
$yaml += "mode: rule`n"
$yaml += "log-level: info`n`n"

$yaml += "dns:`n"
$yaml += "  enable: true`n"
$yaml += "  ipv6: false`n"
$yaml += "  enhanced-mode: fake-ip`n"
$yaml += "  nameserver:`n"
$yaml += "    - 1.1.1.1`n"
$yaml += "    - 8.8.8.8`n`n"

$yaml += "proxies:`n"

foreach ($line in $vlessLines) {

    try {
        $clean = $line.Trim()

        $uuid = ($clean -split "vless://")[1].Split("@")[0]
        $afterAt = $clean.Split("@")[1]

        $serverPort = $afterAt.Split("?")[0]
        $server = $serverPort.Split(":")[0]
        $port = $serverPort.Split(":")[1]

        $query = $afterAt.Split("?")[1].Split("#")[0]
        $params = @{}
        foreach ($pair in $query.Split("&")) {
            if ($pair -match "=") {
                $k,$v = $pair.Split("=",2)
                $params[$k] = $v
            }
        }

        $name = "$server-$port"
        if ($proxyNames -contains $name) { continue }
        $proxyNames += $name

        $yaml += "  - name: `"$name`"`n"
        $yaml += "    type: vless`n"
        $yaml += "    server: $server`n"
        $yaml += "    port: $port`n"
        $yaml += "    uuid: $uuid`n"
        $yaml += "    network: tcp`n"
        $yaml += "    udp: true`n"

        if ($params["security"] -eq "reality") {
            $yaml += "    tls: true`n"
            $yaml += "    flow: xtls-rprx-vision`n"
            $yaml += "    servername: $($params["sni"])`n"
            $yaml += "    reality-opts:`n"
            $yaml += "      public-key: $($params["pbk"])`n"
            $yaml += "      short-id: $($params["sid"])`n"
            $yaml += "    client-fingerprint: chrome`n"
        }
        else {
            $yaml += "    tls: true`n"
        }

        $yaml += "`n"

    } catch {}
}

# ---------- GROUPS ----------
$yaml += "proxy-groups:`n"

$yaml += "  - name: Auto`n"
$yaml += "    type: url-test`n"
$yaml += "    url: http://www.gstatic.com/generate_204`n"
$yaml += "    interval: 300`n"
$yaml += "    proxies:`n"

foreach ($name in $proxyNames) {
    $yaml += "      - $name`n"
}

$yaml += "`n  - name: Proxy`n"
$yaml += "    type: select`n"
$yaml += "    proxies:`n"
$yaml += "      - Auto`n"
$yaml += "      - DIRECT`n"

foreach ($name in $proxyNames) {
    $yaml += "      - $name`n"
}

# ---------- RULES ----------
$yaml += "`nrules:`n"
$yaml += "  - MATCH,Proxy`n"

$yaml | Set-Content $outputFile -Encoding UTF8

Write-Host "Clash YAML generated successfully"

