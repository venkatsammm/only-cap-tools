using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

internal static class CapsLockHelper
{
    private const int Port = 47320;
    private static readonly object BlinkLock = new object();

    private const uint INPUT_KEYBOARD = 1;
    private const uint KEYEVENTF_KEYUP = 0x0002;
    private const ushort VK_CAPITAL = 0x14;

    [StructLayout(LayoutKind.Sequential)]
    private struct KEYBDINPUT
    {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    // The union must be sized by its largest member (MOUSEINPUT), otherwise
    // SendInput rejects the call with ERROR_INVALID_PARAMETER (87).
    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct INPUT
    {
        [FieldOffset(0)] public uint type;
        [FieldOffset(8)] public MOUSEINPUT mi;
        [FieldOffset(8)] public KEYBDINPUT ki;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    private static extern short GetKeyState(int nVirtKey);

    [DllImport("user32.dll")]
    private static extern bool GetKeyboardState(byte[] lpKeyState);

    [DllImport("user32.dll")]
    private static extern int GetKeyboardType(int nTypeFlag);

    private static void TapCapsLock()
    {
        var inputs = new INPUT[2];
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].ki.wVk = VK_CAPITAL;
        inputs[1].type = INPUT_KEYBOARD;
        inputs[1].ki.wVk = VK_CAPITAL;
        inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;
        SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
    }

    private static bool CapsLockOn()
    {
        return (GetKeyState(VK_CAPITAL) & 0x0001) != 0;
    }

    private static void Blink(int count)
    {
        lock (BlinkLock)
        {
            bool startedOn = CapsLockOn();
            for (int i = 0; i < count; i++)
            {
                TapCapsLock();
                Thread.Sleep(140);
                TapCapsLock();
                Thread.Sleep(160);
            }
            if (CapsLockOn() != startedOn)
            {
                TapCapsLock();
            }
        }
    }

    private static bool KeyboardPresent()
    {
        try
        {
            return GetKeyboardType(0) != 0;
        }
        catch
        {
            return true;
        }
    }

    private static void Main()
    {
        TcpListener listener;
        try
        {
            listener = new TcpListener(IPAddress.Loopback, Port);
            listener.Start();
        }
        catch (SocketException)
        {
            // Another instance already serves the port.
            return;
        }

        while (true)
        {
            TcpClient client;
            try
            {
                client = listener.AcceptTcpClient();
            }
            catch (SocketException)
            {
                continue;
            }

            ThreadPool.QueueUserWorkItem(delegate(object state) { Handle((TcpClient)state); }, client);
        }
    }

    private static void Handle(TcpClient client)
    {
        try
        {
            using (client)
            {
                client.ReceiveTimeout = 5000;
                client.SendTimeout = 5000;
                NetworkStream stream = client.GetStream();

                string requestLine = ReadLine(stream);
                if (requestLine == null)
                {
                    return;
                }

                int contentLength = 0;
                string line;
                while ((line = ReadLine(stream)) != null && line.Length > 0)
                {
                    int colon = line.IndexOf(':');
                    if (colon > 0 && line.Substring(0, colon).Trim().Equals("Content-Length", StringComparison.OrdinalIgnoreCase))
                    {
                        int.TryParse(line.Substring(colon + 1).Trim(), out contentLength);
                    }
                }

                string body = "";
                if (contentLength > 0)
                {
                    byte[] buffer = new byte[contentLength];
                    int read = 0;
                    while (read < contentLength)
                    {
                        int n = stream.Read(buffer, read, contentLength - read);
                        if (n <= 0)
                        {
                            break;
                        }
                        read += n;
                    }
                    body = Encoding.UTF8.GetString(buffer, 0, read);
                }

                string[] parts = requestLine.Split(' ');
                string method = parts.Length > 0 ? parts[0].ToUpperInvariant() : "";
                string path = parts.Length > 1 ? parts[1].Split('?')[0] : "";

                if (method == "GET" && path == "/status")
                {
                    string keyboard = KeyboardPresent() ? "found" : "missing";
                    Respond(stream, 200, "{\"ok\":true,\"keyboard\":\"" + keyboard + "\"}");
                }
                else if (method == "POST" && path == "/blink")
                {
                    int count = ParseCount(body);
                    Blink(count);
                    Respond(stream, 200, "{\"ok\":true,\"blinked\":" + count + "}");
                }
                else if (method == "GET" && path == "/")
                {
                    Respond(stream, 200, "{\"ok\":true,\"keyboard\":\"" + (KeyboardPresent() ? "found" : "missing") + "\"}");
                }
                else
                {
                    Respond(stream, 404, "{\"ok\":false}");
                }
            }
        }
        catch
        {
            // Fire-and-forget contract: never surface errors.
        }
    }

    private static int ParseCount(string body)
    {
        int count = 1;
        int idx = body.IndexOf("\"count\"", StringComparison.OrdinalIgnoreCase);
        if (idx >= 0)
        {
            int colon = body.IndexOf(':', idx);
            if (colon >= 0)
            {
                int i = colon + 1;
                while (i < body.Length && (body[i] == ' ' || body[i] == '\t'))
                {
                    i++;
                }
                int j = i;
                while (j < body.Length && char.IsDigit(body[j]))
                {
                    j++;
                }
                if (j > i)
                {
                    int.TryParse(body.Substring(i, j - i), out count);
                }
            }
        }
        if (count < 1) return 1;
        if (count > 5) return 5;
        return count;
    }

    private static string ReadLine(Stream stream)
    {
        var sb = new StringBuilder();
        int b;
        while ((b = stream.ReadByte()) != -1)
        {
            if (b == '\n')
            {
                if (sb.Length > 0 && sb[sb.Length - 1] == '\r')
                {
                    sb.Length--;
                }
                return sb.ToString();
            }
            sb.Append((char)b);
            if (sb.Length > 8192)
            {
                return null;
            }
        }
        return null;
    }

    private static void Respond(Stream stream, int status, string json)
    {
        string reason = status == 200 ? "OK" : "Not Found";
        byte[] payload = Encoding.UTF8.GetBytes(json);
        string header =
            "HTTP/1.1 " + status + " " + reason + "\r\n" +
            "Content-Type: application/json\r\n" +
            "Content-Length: " + payload.Length + "\r\n" +
            "Connection: close\r\n\r\n";
        byte[] head = Encoding.ASCII.GetBytes(header);
        stream.Write(head, 0, head.Length);
        stream.Write(payload, 0, payload.Length);
        stream.Flush();
    }
}
