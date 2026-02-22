$inputFile = "all_sources.txt"
$outputFiltered = "filtered_vless.txt"
$outputFinal = "vless_list_new.txt"

if (!(Test-Path $inputFile)) {
    Write-Host "all_sources.txt not found"
    exit 1
}

# ===== ТВОЙ БЕЛЫЙ СПИСОК =====
$allowed = @(
"146.185.240.23:443",
"79.137.175.44:443",
"87.239.110.251:443",
"84.201.129.41:8443",
"158.160.197.213:443",
"158.160.223.36:443",
"95.163.211.158:8443",
"51.250.26.102:443",
"212.233.95.129:4443"
)

# Берем только vless строки
$vlessLines = Get-Content $inputFile | Where-Object { $_ -match "^vless://" }

$seen = @{}
$result = @()

foreach ($line in $vlessLines) {

    if ($line -match "vless://.*@([^:]+):(\d+)") {

        $key = "$($matches[1]):$($matches[2])"

        # проверяем есть ли в whitelist
        if ($allowed -contains $key) {

            # убираем дубли
            if (-not $seen.ContainsKey($key)) {
                $seen[$key] = $true
                $result += $line
            }
        }
    }
}

$result | Set-Content $outputFiltered
$result | Set-Content $outputFinal

Write-Host "Allowed unique servers:" $result.Count

