Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Dpi {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
[Dpi]::SetProcessDPIAware() | Out-Null

$p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1
if ($p) {
  [Dpi]::ShowWindow($p.MainWindowHandle, 3) | Out-Null
  [Dpi]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
}
Start-Sleep -Milliseconds 1200
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
$bmp.Save("C:\Users\user\Documents\Qoder\2026-10-28\1c4bd53f\shot.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"captured $($b.Width)x$($b.Height)"
