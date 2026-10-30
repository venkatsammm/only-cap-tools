param([string]$Keys)
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait($Keys)
"sent: $Keys"
