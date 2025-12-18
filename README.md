# Huion USB Hub Auto-Recovery (Windows)

Small PowerShell + Task Scheduler setup that automatically fixes a Huion tablet when the **internal USB hub fails after sleep/resume** and shows up as:

- `USB\VID_0000&PID_0002`
- “Device Descriptor Request Failed”
- **Kernel-PnP** event: **Microsoft-Windows-Kernel-PnP/Device Configuration** → **Event ID 411**

When that event happens, Task Scheduler runs the script, which force-binds the **Generic SuperSpeed USB Hub** driver (`usbhub3.inf`) for the failed hub (port-anchored), then restarts Huion software.

---

## Files

- `huion_hub_recover.ps1` — recovery script
- `devcon.exe` — Microsoft Device Console (**required**, place next to the script)
- `README.md` — this file

> `devcon.exe` must be in the same folder as `huion_hub_recover.ps1`.

---

## Quick setup

### 1) Pick a fixed motherboard USB port
Plug the Huion into the USB port you will always use.

### 2) Find the port tail (`&0&XX`)
Run PowerShell **as Administrator**:

```powershell
Get-PnpDevice -PresentOnly |
Where-Object { $_.InstanceId -like "USB\VID_1A40&PID_0101*" } |
Select FriendlyName, InstanceId
```

Example output:

```
USB\VID_1A40&PID_0101\6&3365FBAF&0&14
```

Your **port tail** is the last part:

```
&0&14
```

### 3) Configure the script
Edit `huion_hub_recover.ps1` and set:

```powershell
$PORT_TAIL = "&0&14"
```

Also adjust the Huion executable path if needed:

```powershell
$HUION_UI = "C:\Program Files\Huion Tablet\HuionTablet.exe"
```

### 4) Test the script manually
Trigger the failure (sleep → resume until the USB error happens), then run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Scripts\huion_hub_recover.ps1"
```

If the tablet comes back, you’re good.

---

## Auto-run on failure (Task Scheduler)

Create a **new task** (not “Basic Task”).

### General
- ✅ Run whether user is logged on or not
- ✅ Run with highest privileges

### Trigger
- Begin the task: **On an event**
- Log: **Microsoft-Windows-Kernel-PnP/Device Configuration**
- Source: **Microsoft-Windows-Kernel-PnP**
- Event ID: **411**

### Action
Program/script:

```
powershell.exe
```

Arguments:

```
-WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Scripts\huion_hub_recover.ps1"
```

(Optional) Start in:

```
C:\Scripts
```

---

## Notes
- This is a workaround for a hub enumeration/driver-binding problem.
- Other Huion models may need different VID/PID or a different `PORT_TAIL`. Edit the script accordingly.
