$ErrorActionPreference = "Stop"
$base = "http://127.0.0.1:47320"

$status = Invoke-RestMethod -Uri "$base/status" -Method Get
Write-Output ("status: ok=" + $status.ok + " keyboard=" + $status.keyboard)

$results = @()
foreach ($n in 1..4) {
    $samples = New-Object System.Collections.ArrayList
    $job = Start-Job -ScriptBlock {
        param($c)
        Invoke-RestMethod -Uri "http://127.0.0.1:47320/blink" -Method Post -ContentType "application/json" -Body ("{""count"":" + $c + "}") | Out-Null
    } -ArgumentList $n
    $limit = 400 * $n + 900
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $limit) {
        [void]$samples.Add([int][Console]::CapsLock)
        Start-Sleep -Milliseconds 30
    }
    Wait-Job $job | Remove-Job
    $t = 0
    for ($i = 1; $i -lt $samples.Count; $i++) { if ($samples[$i] -ne $samples[$i - 1]) { $t++ } }
    $letters = @("A", "B", "C", "D")[$n - 1]
    $results += [pscustomobject]@{
        count     = $n
        letter    = $letters
        edges     = $t
        expected  = 2 * $n
        finalCaps = $samples[$samples.Count - 1]
    }
}
$results | Format-Table -AutoSize | Out-String -Width 80
