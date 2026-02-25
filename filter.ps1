# ==============================
# SIMPLE NODE FILTER SYSTEM
# ==============================

$inputFile  = "all_sources.txt"
$outputFile = "filtered_nodes.txt"
$stateFile  = "state.json"

$deleteLimit = 5

# ===== Prefix whitelist =====
$allowed = @{
    "79.137.175."  = @("443")
    "95.163.211."  = @("443")
    "212.233.98."  = @("8443")
    "212.233.123." = @("8443")
    "89.208.222."  = @("8443")
    "95.163.210." = @("443")
    "95.163.211." = @("443")
    "109.120."    = @("443")
    "217.16."     = @("443")
    "51.250."     = @("443")
    "84.252."     = @("443")
}

# ===== Load state =====
if (Test-Path $stateFile) {
    $stateRaw = Get-Content $stateFile -Raw | ConvertFrom-Json
    $state = @{} + $stateRaw
}
else {
    $state = @{}
}

$filtered = @()

# ===== Main loop =====
Get-Content $inputFile | ForEach-Object {

    if ($_ -match "@([0-9\.]+):(\d+)") {

        $ip   = $matches[1]
        $port = $matches[2]
        $ipPort = "${ip}:${port}"

        $allowedMatch = $false

        foreach ($prefix in $allowed.Keys) {
            if ($ip.StartsWith($prefix) -and $allowed[$prefix] -contains $port) {
                $allowedMatch = $true
                break
            }
        }

        if (-not $allowedMatch) {
            return
        }

        # Auto-add to state
        if (-not $state.ContainsKey($ipPort)) {
            $state[$ipPort] = 0
        }

        # Simulated health check (replace with real check if нужно)
        $tcp = Test-NetConnection -ComputerName $ip -Port $port -WarningAction SilentlyContinue

        if ($tcp.TcpTestSucceeded) {

            $state[$ipPort] = 0
            $filtered += $_
        }
        else {
            $state[$ipPort]++

            if ($state[$ipPort] -ge $deleteLimit) {
                $state.Remove($ipPort)
            }
        }
    }
}

# ===== Save results =====
$filtered | Set-Content $outputFile

$state | ConvertTo-Json -Depth 3 | Set-Content $stateFile

Write-Host "Done. Saved to $outputFile"
