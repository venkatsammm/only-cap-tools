$ErrorActionPreference = "Stop"
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class K2 {
    [StructLayout(LayoutKind.Sequential)] public struct MI { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] public struct KI { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] public struct INPUT { [FieldOffset(0)] public uint type; [FieldOffset(8)] public MI mi; [FieldOffset(8)] public KI ki; }
    [DllImport("user32.dll", SetLastError=true)] public static extern uint SendInput(uint n, INPUT[] a, int cb);
    public static void Combo(ushort mod, ushort key) {
        int sz = Marshal.SizeOf(typeof(INPUT));
        INPUT[] d = new INPUT[4];
        d[0].type = 1; d[0].ki.wVk = mod;
        d[1].type = 1; d[1].ki.wVk = key;
        d[2].type = 1; d[2].ki.wVk = key; d[2].ki.dwFlags = 2;
        d[3].type = 1; d[3].ki.wVk = mod; d[3].ki.dwFlags = 2;
        SendInput(4, d, sz);
    }
}
"@

$log = "C:\Users\user\AppData\Roaming\only-cap-version\only-cap.log"
$before = (Get-Content $log).Count

Start-Process "C:\Users\user\Documents\Qoder\2026-10-28\1c4bd53f\mcq-test.html"
Start-Sleep -Seconds 4
Write-Output "html opened, sending Ctrl+M"
[K2]::Combo(0x11, 0x4D)

$samples = New-Object System.Collections.ArrayList
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.ElapsedMilliseconds -lt 14000) {
    [void]$samples.Add([int][Console]::CapsLock)
    Start-Sleep -Milliseconds 40
}
$sw.Stop()
$t = 0
for ($i = 1; $i -lt $samples.Count; $i++) { if ($samples[$i] -ne $samples[$i - 1]) { $t++ } }
Write-Output ("capsEdges=" + $t + " finalCaps=" + $samples[$samples.Count - 1])

Write-Output "--- new log ---"
Get-Content $log | Select-Object -Skip $before

[K2]::Combo(0x11, 0x57)   # Ctrl+W closes the test tab
Write-Output "closed test tab"
