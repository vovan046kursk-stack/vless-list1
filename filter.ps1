# ==========================================
# FILTER1 - PREFIX + UNIVERSAL CIDR
# Output: vless_list_new.txt
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

# ===== PREFIX + PORT WHITELIST =====
$allowed = @{
    "79.137.175."  = @("443")
    "212.233.98."  = @("8443")
    "212.233.123." = @("8443")
    "89.208.222."  = @("8443")
    "95.163.210."  = @("443")
    "95.163.211."  = @("443")
    "109.120."     = @("443")
    "217.16."      = @("443")
    "51.250."      = @("443")
    }

# ===== CIDR BLACKLIST =====
$blockedCIDR = @(
    "95.163.210.0/24",
    "109.120.190.0/23"
)

# ===== UNIVERSAL CIDR FUNCTION =====
function Test-IPInCIDR {
    param(
        [string]$IP,
        [string]$CIDR
    )

    $parts = $CIDR.Split('/')
    $network = [System.Net.IPAddress]::Parse($parts[0])
    $prefixLength = [int]$parts[1]

    $ipBytes = [System.Net.IPAddress]::Parse($IP).GetAddressBytes()
    $networkBytes = $network.GetAddressBytes()

    [Array]::Reverse($ipBytes)
    [Array]::Reverse($networkBytes)

    $ipInt = [BitConverter]::ToUInt32($ipBytes, 0)
    $networkInt = [BitConverter]::ToUInt32($networkBytes, 0)

    $mask = [uint32]0
    if ($prefixLength -ne 0) {
        $mask = [uint32]::MaxValue -shl (32 - $prefixLength)
    }

    return (($ipInt -band $mask) -eq ($networkInt -band $mask))
}

# ===== START =====
if (!(Test-Path $inputFile)) {
    Write-Host "Input file not found!"
    exit 1
}

$lines = Get-Content $inputFile

Write-Host "Total lines:" $lines.Count

# ===== PARAM FILTER =====
$filtered = $lines | Where-Object {
    $_ -match "^vless://" -and
    $_ -match "security=reality" -and
    $_ -match "flow=xtls-rprx-vision" -and
    $_ -match "type=tcp" -and
    $_ -match "fp=chrome"
}

Write-Host "After param filter:" $filtered.Count

$unique = @{}
$result = @()

foreach ($line in $filtered) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]

        # ===== PREFIX + PORT CHECK =====
        $allowedMatch = $false

        foreach ($prefix in $allowed.Keys) {
            if ($ip.StartsWith($prefix) -and $allowed[$prefix] -contains $port) {
                $allowedMatch = $true
                break
            }
        }

        if (-not $allowedMatch) { continue }

        # ===== CIDR BLACKLIST CHECK =====
        $blocked = $false
        foreach ($cidr in $blockedCIDR) {
            if (Test-IPInCIDR -IP $ip -CIDR $cidr) {
                $blocked = $true
                break
            }
        }

        if ($blocked) { continue }

        # ===== REMOVE DUPLICATE IP =====
        if (-not $unique.ContainsKey($ip)) {
            $unique[$ip] = $true
            $result += $line
        }
    }
}

Write-Host "Final count:" $result.Count

# ===== LIMIT OUTPUT =====
$final = $result | Select-Object -First 50

$final | Set-Content $outputFile

Write-Host "Done. Saved to $outputFile"
