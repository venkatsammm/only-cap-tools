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

$q = New-Object System.Windows.Forms.Label
$q.Text = "Which planet is known as the Red Planet?"
$q.Font = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)
$q.AutoSize = $true
$q.Location = New-Object System.Drawing.Point(80, 120)
$form.Controls.Add($q)

$y = 260
foreach ($o in @("A) Venus", "B) Mars", "C) Jupiter", "D) Mercury")) {
  $l = New-Object System.Windows.Forms.Label
  $l.Text = $o
  $l.Font = New-Object System.Drawing.Font("Segoe UI", 24)
  $l.AutoSize = $true
  $l.Location = New-Object System.Drawing.Point(120, $y)
  $form.Controls.Add($l)
  $y += 70
}

# Keep it on screen; force foreground this time
$form.Show()
$form.Activate()
$form.TopMost = $true
[System.Windows.Forms.Application]::DoEvents()
Start-Sleep -Milliseconds 1500
[System.Windows.Forms.Application]::DoEvents()

# Send Ctrl+M system-wide
[System.Windows.Forms.SendKeys]::SendWait("^m")
"sent Ctrl+M"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$edges = 0
$prev = [Console]::CapsLock
$finalCaps = $prev
$captured = $false
while ($sw.Elapsed.TotalSeconds -lt 16) {
  [System.Windows.Forms.Application]::DoEvents()
  $c = [Console]::CapsLock
  if ($c -ne $prev) { $edges++; $prev = $c; $finalCaps = $c }
  if (-not $captured -and $sw.Elapsed.TotalSeconds -gt 6) {
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
    $bmp.Save("C:\Users\user\Documents\Qoder\2026-10-28\1c4bd53f\screen-mcq.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    $captured = $true
  }
  Start-Sleep -Milliseconds 50
}
$form.Close()
"capsEdges=$edges finalCaps=$finalCaps"

Start-Sleep -Milliseconds 500
$lines = Get-Content $logPath
$new = $lines[($before)..($lines.Count - 1)]
"--- new log lines ---"
$new | ForEach-Object { $_ }
