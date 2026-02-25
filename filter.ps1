# ==========================================
# FILTER1 - PREFIX + PARTIAL AUTO CIDR CUT
# Output: vless_list_new.txt
# ==========================================

$inputFile  = "all_sources.txt"
$outputFile = "vless_list_new.txt"

# ===== PREFIX + PORT WHITELIST =====
$allowed = @{
    "212.233.98."  = @("8443")
    "212.233.123." = @("8443")
    "212.233.121." = @("8443")
    "89.208.222."  = @("8443")
    "95.163.183."  = @("443")
    "81.200.151."  = @("443")
    "51.250.75."    = @("443")
    "51.250.6."    = @("443")
    "51.250.14."    = @("443")
    "95.163.211."  = @("443")
    "109.120."     = @("443")
    "79.137.174."  = @("8443")
    }

# ===== STATIC BLOCKED CIDR (ручной список) =====
$blockedCIDR = @(
    
)

# ===== AUTO CUT THRESHOLD =====
# если в одной /24 больше 6 IP → считаем спам-пулом
$autoCutThreshold = 6

# ===== UNIVERSAL CIDR CHECK =====
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

# ===== PARAM FILTER =====
$filtered = $lines | Where-Object {
    $_ -match "^vless://" -and
    $_ -match "security=reality" -and
    $_ -match "flow=xtls-rprx-vision" -and
    $_ -match "type=tcp" -and
    $_ -match "fp=chrome"
}

# ===== COLLECT IPs FOR AUTO ANALYSIS =====
$ipList = @()

foreach ($line in $filtered) {
    if ($line -match "@([^:]+):(\d+)") {
        $ip = $matches[1]
        $ipList += $ip
    }
}

# ===== GROUP BY /24 =====
$groups = @{}

foreach ($ip in $ipList) {
    $parts = $ip.Split(".")
    $prefix24 = "$($parts[0]).$($parts[1]).$($parts[2]).0/24"

    if (-not $groups.ContainsKey($prefix24)) {
        $groups[$prefix24] = 0
    }

    $groups[$prefix24]++
}

# ===== AUTO ADD HEAVY /24 TO BLACKLIST =====
foreach ($net in $groups.Keys) {
    if ($groups[$net] -gt $autoCutThreshold) {
        $blockedCIDR += $net
        Write-Host "Auto-blocked:" $net "Count:" $groups[$net]
    }
}

# ===== MAIN FILTER =====
$unique = @{}
$result = @()

foreach ($line in $filtered) {

    if ($line -match "@([^:]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]

        # PREFIX + PORT CHECK
        $allowedMatch = $false

        foreach ($prefix in $allowed.Keys) {
            if ($ip.StartsWith($prefix) -and $allowed[$prefix] -contains $port) {
                $allowedMatch = $true
                break
            }
        }

        if (-not $allowedMatch) { continue }

        # CIDR BLACKLIST CHECK
        $blocked = $false
        foreach ($cidr in $blockedCIDR) {
            if (Test-IPInCIDR -IP $ip -CIDR $cidr) {
                $blocked = $true
                break
            }
        }

        if ($blocked) { continue }

        # REMOVE DUPLICATES
        if (-not $unique.ContainsKey($ip)) {
            $unique[$ip] = $true
            $result += $line
        }
    }
}

Write-Host "Final count:" $result.Count

# LIMIT OUTPUT
$final = $result | Select-Object -First 50
$final | Set-Content $outputFile

Write-Host "Done. Saved to $outputFile"
