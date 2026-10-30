$ErrorActionPreference = "Stop"
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class K {
    [StructLayout(LayoutKind.Sequential)] public struct MI { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] public struct KI { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] public struct INPUT { [FieldOffset(0)] public uint type; [FieldOffset(8)] public MI mi; [FieldOffset(8)] public KI ki; }
    [DllImport("user32.dll", SetLastError=true)] public static extern uint SendInput(uint n, INPUT[] a, int cb);
    public static void Combo(ushort vkCtrl, ushort vkKey) {
        int sz = Marshal.SizeOf(typeof(INPUT));
        INPUT[] d = new INPUT[4];
        d[0].type = 1; d[0].ki.wVk = vkCtrl;
        d[1].type = 1; d[1].ki.wVk = vkKey;
        d[2].type = 1; d[2].ki.wVk = vkKey; d[2].ki.dwFlags = 2;
        d[3].type = 1; d[3].ki.wVk = vkCtrl; d[3].ki.dwFlags = 2;
        uint sent = SendInput(4, d, sz);
        if (sent != 4) throw new Exception("SendInput sent " + sent + " err=" + Marshal.GetLastWin32Error());
    }
}
"@

$log = "C:\Users\user\AppData\Roaming\only-cap-version\only-cap.log"
$beforeLines = (Get-Content $log).Count
Write-Output ("log lines before: " + $beforeLines)

[K]::Combo(0x11, 0x4D)   # Ctrl + M
Write-Output "sent Ctrl+M"

$samples = New-Object System.Collections.ArrayList
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.ElapsedMilliseconds -lt 9000) {
    [void]$samples.Add([int][Console]::CapsLock)
    Start-Sleep -Milliseconds 40
}

$transitions = 0
for ($i = 1; $i -lt $samples.Count; $i++) { if ($samples[$i] -ne $samples[$i - 1]) { $transitions++ } }
Write-Output ("capsTransitions=" + $transitions + " finalState=" + $samples[$samples.Count - 1])
Write-Output ("capsSeq=" + ($samples -join ""))

Write-Output "--- new log lines ---"
Get-Content $log | Select-Object -Skip $beforeLines
