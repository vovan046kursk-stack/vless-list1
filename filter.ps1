# ====== CLEAN OLD FINAL ======
if (Test-Path "vless_list_new.txt") {
    Remove-Item "vless_list_new.txt"
}

# ====== LOAD ALLOWED IP:PORT ======
$allowed = Get-Content ip_port_pool.txt | ForEach-Object { $_.Trim() }

$good = @()
$seen = @{}

# ====== FILTER VLESS ======
Get-Content all_vless.txt | ForEach-Object {

    $line = $_.Trim()

    if (!$line.StartsWith("vless://")) { return }

    if ($line -match "TG:") { return }

    if ($line -match '@([\d\.]+:\d+)') {

        $ip = $matches[1]

        if ($allowed -contains $ip) {

            if (!$seen.ContainsKey($line)) {

                $seen[$line] = $true
                $good += $line
            }
        }
    }
}

# ====== WRITE FINAL ======
$good | Set-Content vless_list_new.txt -Encoding UTF8
