$ErrorActionPreference = "Stop"
$base = "http://127.0.0.1:47320"
$status = Invoke-RestMethod -Uri "$base/status" -Method Get
Write-Output ("status ok=" + $status.ok + " keyboard=" + $status.keyboard)

$before = [Console]::CapsLock
$samples = New-Object System.Collections.ArrayList
$job = Start-Job -ScriptBlock {
    Invoke-RestMethod -Uri "http://127.0.0.1:47320/blink" -Method Post -ContentType "application/json" -Body '{"count":3}' | Out-Null
}
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.ElapsedMilliseconds -lt 2200) {
    [void]$samples.Add([int][Console]::CapsLock)
    Start-Sleep -Milliseconds 50
}
Wait-Job $job | Receive-Job | Out-Null
$sw.Stop()

$transitions = 0
for ($i = 1; $i -lt $samples.Count; $i++) { if ($samples[$i] -ne $samples[$i - 1]) { $transitions++ } }
Write-Output ("capsBefore=" + $before + " capsAfter=" + [Console]::CapsLock + " transitions=" + $transitions)
Write-Output ("sampleSeq=" + ($samples -join ""))
