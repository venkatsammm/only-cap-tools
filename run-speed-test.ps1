Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$logPath = "C:\Users\user\AppData\Roaming\only-cap-version\only-cap.log"
$before = 0
if (Test-Path $logPath) { $before = (Get-Content $logPath | Measure-Object -Line).Lines }

$form = New-Object System.Windows.Forms.Form
$form.Text = "MCQ Test"
$form.WindowState = "Maximized"
$form.FormBorderStyle = "None"
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::White
$form.ShowInTaskbar = $false

function Add-Lbl($text, $font, $x, $y) {
  $l = New-Object System.Windows.Forms.Label
  $l.Text = $text
  $l.Font = $font
  $l.AutoSize = $true
  $l.Location = New-Object System.Drawing.Point($x, $y)
  $form.Controls.Add($l)
}
Add-Lbl "Which planet is known as the Red Planet?" (New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)) 80 120
$y = 260
foreach ($o in @("A) Venus", "B) Mars", "C) Jupiter", "D) Mercury")) {
  Add-Lbl $o (New-Object System.Drawing.Font("Segoe UI", 24)) 120 $y
  $y += 70
}

$form.Show()
$form.Activate()
$form.TopMost = $true
for ($i = 0; $i -lt 20; $i++) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }

$prev = [Console]::CapsLock
for ($round = 1; $round -le 3; $round++) {
  $mark = (Get-Content $logPath | Measure-Object -Line).Lines
  [System.Windows.Forms.SendKeys]::SendWait("^m")
  "round ${round}: sent Ctrl+M"
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $done = $false
  while ($sw.Elapsed.TotalSeconds -lt 20 -and -not $done) {
    [System.Windows.Forms.Application]::DoEvents()
    $c = [Console]::CapsLock
    if ($c -ne $prev) { $prev = $c }
    Start-Sleep -Milliseconds 60
    $tail = Get-Content $logPath -Tail 1
    if ($tail -match "Processing finished|No blink") { $done = $true }
  }
  Start-Sleep -Milliseconds 600
  "  round ${round}: done=$done after $([int]$sw.Elapsed.TotalMilliseconds) ms"
  Start-Sleep -Seconds 1
}
$form.Close()

Start-Sleep -Milliseconds 400
$lines = Get-Content $logPath
$new = $lines[($before)..($lines.Count - 1)]
"--- new log lines ---"
$new | ForEach-Object { $_ }

# Compute per-run duration from timestamps
$ts = { param($l) [datetime]::Parse($l.Substring(0, 24)).ToUniversalTime() }
$start = $null
foreach ($l in $new) {
  if ($l -match "\[Shortcut\] Ctrl\+M") { $start = & $ts $l }
  elseif ($l -match "\[CapsLockClient\] blink .* ok") {
    "RUN total: $([int]((& $ts $l) - $start).TotalMilliseconds) ms"
  }
}
