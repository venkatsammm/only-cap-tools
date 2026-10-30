$envPath = "$env:LOCALAPPDATA\Programs\Only Cap\resources\.env"
$newKey = (Get-Clipboard).Trim()
if ($newKey -notmatch '^AQ\.') { throw "clipboard does not look like an API key" }

Copy-Item $envPath "$envPath.bak2" -Force
$lines = Get-Content $envPath
$found = $false
$lines = $lines | ForEach-Object {
    if ($_ -match '^GEMINI_API_KEY=') {
        $found = $true
        $cur = $_.Substring('GEMINI_API_KEY='.Length).Trim()
        if ($cur -split ',' -contains $newKey) { $_ }
        elseif ($cur.Length -gt 0) { "GEMINI_API_KEY=$cur,$newKey" }
        else { "GEMINI_API_KEY=$newKey" }
    } else { $_ }
}
if (-not $found) { $lines += "GEMINI_API_KEY=$newKey" }
Set-Content -Path $envPath -Value $lines -Encoding ASCII

$val = ((Get-Content $envPath | Where-Object { $_ -match '^GEMINI_API_KEY=' }) -replace '^GEMINI_API_KEY=', '')
$keys = $val -split ','
"keys now: $($keys.Count)"
$i = 1
foreach ($k in $keys) { "  [$i] ...$($k.Substring([Math]::Max(0, $k.Length - 6)))"; $i++ }
