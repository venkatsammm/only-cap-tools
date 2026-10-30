param([int]$X, [int]$Y)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Clicker2 {
  [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr dwExtraInfo; }
  [StructLayout(LayoutKind.Explicit)] public struct INPUT { [FieldOffset(0)] public uint type; [FieldOffset(8)] public MOUSEINPUT mi; }
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] inputs, int size);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  public static void Click(IntPtr hwnd, int x, int y) {
    SetProcessDPIAware();
    if (hwnd != IntPtr.Zero) { ShowWindow(hwnd, 3); SetForegroundWindow(hwnd); }
    System.Threading.Thread.Sleep(250);
    SetCursorPos(x, y);
    System.Threading.Thread.Sleep(250);
    var inputs = new INPUT[2];
    inputs[0].type = 0; inputs[0].mi.dwFlags = 0x0002;
    inputs[1].type = 0; inputs[1].mi.dwFlags = 0x0004;
    SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
  }
}
"@
$p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1
$h = if ($p) { $p.MainWindowHandle } else { [IntPtr]::Zero }
[Clicker2]::Click($h, $X, $Y)
"clicked $X,$Y"
