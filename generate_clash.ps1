$input = "filtered_vless.txt"
$output = "clash_pool.yaml"

if (!(Test-Path $input)) {
    Write-Host "filtered_vless.txt not found"
    exit 1
}

$proxyNames = @()
$proxyYaml = ""
$counter = 1

foreach ($line in Get-Content $input) {

    if ($line -match "^vless://([^@]+)@([\d\.]+):(\d+)") {

        $uuid = $matches[1]
        $server = $matches[2]
        $port = $matches[3]

        $name = "$server-$port-$counter"
        $proxyNames += $name

$proxyYaml += @"
  - name: "$name"
    type: vless
    server: $server
    port: $port
    uuid: $uuid
    network: tcp
    tls: true

"@

        $counter++
    }
}

if ($proxyNames.Count -eq 0) {
    Write-Host "No proxies parsed"
    exit 1
}

$config = @"
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info

proxies:
$proxyYaml
proxy-groups:
  - name: Proxy
    type: select
    proxies:
$(($proxyNames | ForEach-Object { "      - $_" }) -join "`n")
      - DIRECT

rules:
  - MATCH,Proxy
"@

$config | Set-Content $output -Encoding UTF8

Write-Host "Clash config generated successfully"
