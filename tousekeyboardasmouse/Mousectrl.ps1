param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("CapsLock", "PrintScreen", "ScrollLock", "PauseBreak")]
    [string]$ToggleKey
)

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class KeyboardMouse
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN    = 0x0100;
    private const int WM_KEYUP      = 0x0101;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int WM_SYSKEYUP   = 0x0105;

    private const uint MOUSEEVENTF_LEFTDOWN  = 0x0002;
    private const uint MOUSEEVENTF_LEFTUP    = 0x0004;
    private const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
    private const uint MOUSEEVENTF_RIGHTUP   = 0x0010;
    private const uint MOUSEEVENTF_WHEEL     = 0x0800;

    private static readonly bool[] Keys = new bool[256];
    private static readonly HookProc HookDelegate = HookCallback;
    private static IntPtr HookHandle = IntPtr.Zero;

    private static uint ToggleVK;
    private static bool MouseMode = false;

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowsHookEx(
        int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll")]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(
        IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    private static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    private static extern void mouse_event(
        uint dwFlags, uint dx, uint dy, int dwData, UIntPtr dwExtraInfo);

    public static void SetToggleKey(uint vk)
    {
        ToggleVK = vk;
    }

    public static bool IsMouseMode()
    {
        return MouseMode;
    }

    public static bool Start()
    {
        HookHandle = SetWindowsHookEx(
            WH_KEYBOARD_LL,
            HookDelegate,
            GetModuleHandle(null),
            0
        );

        return HookHandle != IntPtr.Zero;
    }

    public static void Stop()
    {
        if (HookHandle != IntPtr.Zero)
        {
            UnhookWindowsHookEx(HookHandle);
            HookHandle = IntPtr.Zero;
        }
    }

    public static void ClearKeys()
    {
        Array.Clear(Keys, 0, Keys.Length);
    }

    public static bool IsDown(int vk)
    {
        return vk >= 0 && vk < Keys.Length && Keys[vk];
    }

    public static void MoveMouse(int dx, int dy)
    {
        POINT p;

        if (GetCursorPos(out p))
            SetCursorPos(p.X + dx, p.Y + dy);
    }

    public static void LeftClick()
    {
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero);
        mouse_event(MOUSEEVENTF_LEFTUP,   0, 0, 0, UIntPtr.Zero);
    }

    public static void RightClick()
    {
        mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, UIntPtr.Zero);
        mouse_event(MOUSEEVENTF_RIGHTUP,   0, 0, 0, UIntPtr.Zero);
    }

    public static void LeftDown()
    {
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero);
    }

    public static void LeftUp()
    {
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero);
    }

    public static void Scroll(int amount)
    {
        mouse_event(MOUSEEVENTF_WHEEL, 0, 0, amount, UIntPtr.Zero);
    }

    private static bool IsControlledKey(uint vk)
    {
        switch (vk)
        {
            case 0x26: // UP
            case 0x28: // DOWN
            case 0x25: // LEFT
            case 0x27: // RIGHT
            case 0x51: // Q
            case 0x57: // W
            case 0x41: // A
            case 0x53: // S
            case 0x45: // E
            case 0x44: // D
            case 0xA0: // LEFT SHIFT
            case 0xA1: // RIGHT SHIFT
            case 0x20: // SPACE = hold left mouse button / drag
                return true;

            default:
                return false;
        }
    }

    private static IntPtr HookCallback(
        int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            KBDLLHOOKSTRUCT key =
                Marshal.PtrToStructure<KBDLLHOOKSTRUCT>(lParam);

            uint vk = key.vkCode;

            bool down =
                wParam == (IntPtr)WM_KEYDOWN ||
                wParam == (IntPtr)WM_SYSKEYDOWN;

            bool up =
                wParam == (IntPtr)WM_KEYUP ||
                wParam == (IntPtr)WM_SYSKEYUP;

            // Selected key toggles A Lazy Mouse mode.
            if (vk == ToggleVK)
            {
                if (down)
                {
                    // Ignore auto-repeat: toggle once per physical press.
                    if (!Keys[vk])
                    {
                        MouseMode = !MouseMode;

                        if (!MouseMode && Keys[0x20])
                            LeftUp();

                        Array.Clear(Keys, 0, Keys.Length);
                    }

                    Keys[vk] = true;
                }

                if (up)
                    Keys[vk] = false;

                // Do not pass the selected toggle key to other apps.
                return (IntPtr)1;
            }

            // Normal keyboard mode.
            if (!MouseMode)
            {
                return CallNextHookEx(HookHandle, nCode, wParam, lParam);
            }

            // Mouse mode: intercept only our assigned control keys.
            if (IsControlledKey(vk))
            {
                if (down)
                {
                    if (vk == 0xA0) // Left Shift = left click
                    {
                        if (!Keys[vk])
                            LeftClick();
                    }
                    else if (vk == 0xA1) // Right Shift = right click
                    {
                        if (!Keys[vk])
                            RightClick();
                    }
                    else if (vk == 0x20) // Space = hold left mouse button / drag
                    {
                        if (!Keys[vk])
                            LeftDown();
                    }

                    Keys[vk] = true;
                }

                if (up)
                {
                    if (vk == 0x20 && Keys[vk])
                        LeftUp();

                    Keys[vk] = false;
                }

                return (IntPtr)1;
            }
        }

        return CallNextHookEx(HookHandle, nCode, wParam, lParam);
    }
}
'@

$toggleVKMap = @{
    CapsLock    = 0x14
    PrintScreen = 0x2C
    ScrollLock  = 0x91
    PauseBreak  = 0x13
}

[KeyboardMouse]::SetToggleKey($toggleVKMap[$ToggleKey])

if (-not [KeyboardMouse]::Start())
{
    Write-Host "ERROR: Could not install keyboard hook." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=============================="
Write-Host "        A LAZY MOUSE"
Write-Host "=============================="
Write-Host ""
Write-Host "Toggle key : $ToggleKey"
Write-Host "Press it   : Mouse mode ON/OFF"
Write-Host ""
Write-Host "Arrow Keys = Move"
Write-Host "Q W A S     = Diagonal"
Write-Host "E           = Scroll Up"
Write-Host "D           = Scroll Down"
Write-Host "Left Shift  = Left Click"
Write-Host "Right Shift = Right Click"
Write-Host ""
Write-Host "Ctrl+C in the script console exits."
Write-Host ""

try
{
    while ($true)
    {
        if ([KeyboardMouse]::IsMouseMode())
        {
            $dx = 0
            $dy = 0

            $speed = 8
            $diag = 0.7071

            if ([KeyboardMouse]::IsDown(0x25)) { $dx -= $speed }
            if ([KeyboardMouse]::IsDown(0x27)) { $dx += $speed }
            if ([KeyboardMouse]::IsDown(0x26)) { $dy -= $speed }
            if ([KeyboardMouse]::IsDown(0x28)) { $dy += $speed }

            if ([KeyboardMouse]::IsDown(0x51))
            {
                $dx -= $speed * $diag
                $dy -= $speed * $diag
            }

            if ([KeyboardMouse]::IsDown(0x57))
            {
                $dx += $speed * $diag
                $dy -= $speed * $diag
            }

            if ([KeyboardMouse]::IsDown(0x41))
            {
                $dx -= $speed * $diag
                $dy += $speed * $diag
            }

            if ([KeyboardMouse]::IsDown(0x53))
            {
                $dx += $speed * $diag
                $dy += $speed * $diag
            }

            if ($dx -ne 0 -or $dy -ne 0)
            {
                [KeyboardMouse]::MoveMouse([int]$dx, [int]$dy)
            }

            if ([KeyboardMouse]::IsDown(0x45))
            {
                [KeyboardMouse]::Scroll(120)
            }

            if ([KeyboardMouse]::IsDown(0x44))
            {
                [KeyboardMouse]::Scroll(-120)
            }
        }
        else
        {
            [KeyboardMouse]::ClearKeys()
        }

        Start-Sleep -Milliseconds 8
    }
}
finally
{
    [KeyboardMouse]::Stop()
    [KeyboardMouse]::ClearKeys()
}
