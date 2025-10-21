# Windows Resource Monitor

A real-time PowerShell resource monitor with interactive controls that displays system statistics similar to Windows Resource Monitor, with colorful graphs and process tracking.

## Features

- **Real-time Monitoring** - Updates every 2 seconds
- **Interactive Views** - Toggle between Stats View and Processes View
- **Keyboard Controls** - Show/hide individual sections on the fly
- **CPU Usage** - Overall CPU percentage with history graph
- **Memory Usage** - RAM usage percentage and GB used/total
- **Disk I/O** - Read/Write speeds with total throughput
- **Network Usage** - Send/Receive speeds with total bandwidth
- **Visual Graphs** - ASCII bar graphs and sparkline history charts
- **Top Processes** - Shows top 5-20 processes (depending on visible sections) by:
  - **CPU usage** - sorted by highest CPU time
  - **Memory usage** - sorted by Private Memory in MB
  - **Disk I/O** - sorted by total bytes/sec
  - **Network** - estimated active network processes

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges (recommended for accurate disk/network metrics)

## Usage

### Quick Start

1. Open PowerShell as Administrator (right-click PowerShell → Run as Administrator)
2. Navigate to the directory containing `ResourceMonitor.ps1`
3. Run the script:

```powershell
.\ResourceMonitor.ps1
```

### Keyboard Controls

Once running, use these keys to control the display:

| Key | Action |
|-----|--------|
| **SPACE** | Toggle between Stats View and Processes View |
| **C** | Toggle CPU section on/off |
| **M** | Toggle Memory section on/off |
| **D** | Toggle Disk section on/off |
| **N** | Toggle Network section on/off |
| **Ctrl+C** | Exit the monitor |

### Views

**Stats View (Default)**
- Shows real-time system metrics with graphs
- Displays current values and historical trends
- Visual bar graphs and sparklines

**Processes View (Press SPACE)**
- Shows top processes for each enabled resource
- More processes visible when sections are hidden (up to 20)
- Sorted by relevant metric (CPU time, Memory, Disk I/O)

### Dynamic Process Count

The number of processes shown adapts based on available screen space:
- **All 4 sections visible**: 8 processes per section
- **2-3 sections visible**: 10 processes per section
- **1 section visible**: 15 processes per section
- **No stats sections** (processes only): 20 processes per section

### If Execution Policy Prevents Running

If you encounter an execution policy error, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then try running the script again.

### Exiting

Press `Ctrl+C` to stop the monitor and exit.

## Display Examples

### Stats View

```
===============================================================================
            WINDOWS RESOURCE MONITOR - 2025-10-21 15:09:22 - STATS VIEW
===============================================================================
Controls: [SPACE]=Toggle | [C]=CPU | [M]=Memory | [D]=Disk | [N]=Network

+-- CPU USAGE -----------------------------------------------------------------
| Current:  25.3% | #############.....................................
| History: _........-..........-_........-..........-

+-- MEMORY USAGE --------------------------------------------------------------
| Current:  45.8% | #######################...........................
| Used:      7.32 GB / 16.00 GB
| History: ___________===========================

+-- DISK I/O ------------------------------------------------------------------
| Total:      1.25 MB/s | #########.....................................
| Read:     512.00 KB/s
| Write:    768.00 KB/s
| History: _........-..=......+........*........#

+-- NETWORK -------------------------------------------------------------------
| Total:      2.10 MB/s | ##############....................................
| Sent:     256.00 KB/s
| Received:   1.85 MB/s
| History: __________..............................

Status: CPU:ON | MEM:ON | DISK:ON | NET:ON
```

### Processes View (after pressing SPACE)

```
===============================================================================
            WINDOWS RESOURCE MONITOR - 2025-10-21 15:09:22 - PROCESSES VIEW
===============================================================================
Controls: [SPACE]=Toggle | [C]=CPU | [M]=Memory | [D]=Disk | [N]=Network

+-- TOP PROCESSES BY CPU ------------------------------------------------------
| Name                               CPU(s)   Memory(MB)      PID
|------------------------------------------------------------------------------
| chrome                            125.45       856.23     1234
| code                               45.32       512.67     5678
| firefox                            32.18       678.90     9012
| explorer                           12.45       256.34     3456
| powershell                          5.67        89.12     7890
| system                              3.21       123.45     4
| dwm                                 2.15        45.67     1111
| msedge                              1.98       234.56     2222

+-- TOP PROCESSES BY MEMORY ---------------------------------------------------
| Name                               CPU(s)  Private(MB)      PID
|------------------------------------------------------------------------------
| chrome                            125.45      1024.56     1234
| firefox                            32.18       856.78     9012
| code                               45.32       678.90     5678
| msedge                             15.23       512.34     2345
| explorer                           12.45       345.67     3456
| outlook                            10.12       289.01     6789
| teams                               8.45       234.56     7890
| windows defender                    5.32       189.23     1357

+-- TOP PROCESSES BY DISK I/O -------------------------------------------------
| Name                                         Disk I/O (B/s)      PID
|------------------------------------------------------------------------------
| chrome                                            15234567     1234
| system                                             8901234        4
| searchindexer                                      5678901     3456
| windows defender                                   3456789     1357
| code                                               2345678     5678
| explorer                                           1234567     3456
| firefox                                             901234     9012
| outlook                                             567890     6789

+-- TOP PROCESSES BY NETWORK (Estimated) -------------------------------------
| Name                              Status   Memory(MB)      PID
|------------------------------------------------------------------------------
| chrome                            Active       856.23     1234
| firefox                           Active       678.90     9012
| code                              Active       512.67     5678
| teams                             Active       234.56     7890
| outlook                           Active       289.01     6789
| msedge                            Active       234.56     2222
| discord                           Active       156.78     3333
| spotify                           Active        98.45     4444

Status: CPU:ON | MEM:ON | DISK:ON | NET:ON
```

### Selective Section Display (e.g., CPU and Memory only)

Press **D** and **N** to hide Disk and Network sections:

```
===============================================================================
            WINDOWS RESOURCE MONITOR - 2025-10-21 15:09:22 - STATS VIEW
===============================================================================
Controls: [SPACE]=Toggle | [C]=CPU | [M]=Memory | [D]=Disk | [N]=Network

+-- CPU USAGE -----------------------------------------------------------------
| Current:  25.3% | #############.....................................
| History: _........-..........-_........-..........-

+-- MEMORY USAGE --------------------------------------------------------------
| Current:  45.8% | #######################...........................
| Used:      7.32 GB / 16.00 GB
| History: ___________===========================

Status: CPU:ON | MEM:ON | DISK:OFF | NET:OFF
```

Press **SPACE** to see processes (now showing 10 processes per section):

```
+-- TOP PROCESSES BY CPU ------------------------------------------------------
| Name                               CPU(s)   Memory(MB)      PID
|------------------------------------------------------------------------------
| chrome                            125.45       856.23     1234
| code                               45.32       512.67     5678
[...10 total processes...]

+-- TOP PROCESSES BY MEMORY ---------------------------------------------------
| Name                               CPU(s)  Private(MB)      PID
|------------------------------------------------------------------------------
| chrome                            125.45      1024.56     1234
| firefox                            32.18       856.78     9012
[...10 total processes...]

Status: CPU:ON | MEM:ON | DISK:OFF | NET:OFF
```

## Configuration

You can modify these variables at the top of the script:

```powershell
$TopProcessCount = 8        # Base number of processes (dynamically adjusts)
$RefreshInterval = 2        # Refresh rate in seconds
$GraphWidth = 50           # Width of the bar graphs
$HistorySize = 20          # Number of history points for sparkline
```

## Color Coding

- **CPU** - Green
- **Memory** - Magenta
- **Disk I/O** - Blue
- **Network** - Red
- **History Graphs** - Cyan
- **Process Lists** - Yellow/DarkCyan headers
- **Status Bar** - DarkGray

## Notes

- Running as Administrator provides more accurate metrics
- The sparkline history shows the last 20 data points
- Network statistics exclude virtual adapters (isatap, Teredo)
- Memory shown is Private Memory (not Working Set) for process listing
- CPU times are cumulative since process start
- Disk I/O may show 0 if no disk activity is occurring
- Network per-process monitoring is estimated (Windows doesn't provide direct per-process network counters)
- Process count dynamically adjusts based on visible sections to maximize screen usage
- Hidden sections are remembered when toggling between views

## Workflow Examples

**Monitoring System Performance**
1. Start in Stats View to see overall system health
2. Use sparklines to identify trends over time
3. Toggle sections on/off to focus on specific resources

**Identifying Resource-Heavy Processes**
1. Press SPACE to switch to Processes View
2. Hide sections you're not interested in (e.g., press D and N)
3. See more processes for the remaining sections
4. Press C or M to focus on just CPU or Memory

**Comparing Before/After**
1. Watch Stats View during normal operation
2. Press SPACE to check which processes are consuming resources
3. Press SPACE again to return to Stats View
4. Monitor changes after closing heavy applications

## Troubleshooting

**Script won't run:**
- Ensure you're using PowerShell (not Command Prompt)
- Try running PowerShell as Administrator
- Check execution policy: `Get-ExecutionPolicy`

**Keys not responding:**
- Make sure the PowerShell window is in focus
- Some terminals may not support keyboard interception
- Try clicking in the window before pressing keys

**Performance counters not available:**
- Some counters require Administrator privileges
- Windows Performance Counter service may need to be running
- Run: `services.msc` and ensure "Performance Counter DLL Host" is running

**Display issues:**
- Ensure your terminal window is at least 80 characters wide
- Use a monospace font (Consolas, Cascadia Code, Courier New)
- Some older terminals may not render colors correctly

## Tips

- Hide sections you don't need to see more processes
- Use SPACE to quickly compare stats vs processes
- Watch the sparkline history for patterns over time
- Check the status bar to see which sections are active
- Run as Administrator for the most accurate metrics

## License

Free to use and modify as needed.