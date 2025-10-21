# Windows Resource Monitor

A real-time PowerShell resource monitor with interactive controls that displays system statistics similar to Windows Resource Monitor, with colorful graphs and process tracking.

## Features

- **Real-time Monitoring** - Updates every second
- **Two Interactive Views**:
  - **Stats View** - System metrics with graphs and history
  - **Processes View** - Top processes by resource (can show all or focus on one)
- **Flexible Display Modes** - View all resources or focus on a single one
- **Visual Graphs** - ASCII bar graphs and sparkline history charts
- **Adaptive Process Count** - Shows 8-30 processes depending on view mode

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges (recommended for accurate disk/network metrics)

## Usage

### Quick Start

```powershell
.\ResourceMonitor.ps1
```

**Important**: Make sure the PowerShell window has focus for keyboard controls to work!

### Keyboard Controls

The controls behave differently depending on which view you're in:

#### Stats View (Default)
| Key | Action |
|-----|--------|
| **SPACE** | Switch to Processes View |
| **C** | Toggle CPU section on/off |
| **M** | Toggle Memory section on/off |
| **D** | Toggle Disk section on/off |
| **N** | Toggle Network section on/off |

#### Processes View
| Key | Action |
|-----|--------|
| **SPACE** | Switch to Stats View |
| **C** | Show ONLY CPU processes (up to 30) |
| **M** | Show ONLY Memory processes (up to 30) |
| **D** | Show ONLY Disk processes (up to 30) |
| **N** | Show ONLY Network processes (up to 30) |
| **A** | Show ALL sections (8 processes each) |

#### Both Views
| Key | Action |
|-----|--------|
| **Ctrl+C** | Exit the monitor |

### Views Explained

**Stats View**
- Shows real-time system metrics with graphs
- Each section can be toggled on/off independently
- Displays current values, bar graphs, and historical sparklines
- Perfect for monitoring overall system health

**Processes View - All Mode (Default)**
- Shows top 8 processes for each resource type
- Compact view showing all four sections
- Quick overview of what's consuming resources

**Processes View - Single Resource Mode**
- Press C, M, D, or N to focus on ONE resource
- Shows up to 30 processes for that resource
- Fills the screen with detailed process information
- Great for deep-diving into a specific resource bottleneck

### Example Workflows

**Quick System Check**
1. Start in Stats View to see overall metrics
2. Press SPACE to see top processes
3. Press C/M/D/N to investigate a specific resource
4. Press A to return to all sections
5. Press SPACE to return to Stats View

**CPU Troubleshooting**
1. Press SPACE to enter Processes View
2. Press C to show only CPU processes
3. View up to 30 processes sorted by CPU usage
4. Identify the problematic process
5. Press A or SPACE to exit focused view

**Memory Leak Investigation**
1. Press SPACE then M to focus on memory
2. Watch the Private(MB) column for growing processes
3. See up to 30 processes sorted by memory usage

## Display Examples

### Stats View - All Sections

```
===============================================================================
            WINDOWS RESOURCE MONITOR - 2025-10-21 15:33:31 - STATS VIEW
===============================================================================
Controls: [SPACE]=Processes | [C]=CPU | [M]=Memory | [D]=Disk | [N]=Network

+-- CPU USAGE -----------------------------------------------------------------
| Current:  23.4% | ############......................................
| History: ........_....=--+--
+------------------------------------------------------------------------------

+-- MEMORY USAGE --------------------------------------------------------------
| Current:  88.4% | ############################################......
| Used:    13.86 GB / 15.69 GB
| History: @@@@@@@@@@@@@@@@@@@
+------------------------------------------------------------------------------

+-- DISK I/O ------------------------------------------------------------------
| Total:    454.22 KB/s | ##...............................................
| Read:       0 B/s
| Write:    454.22 KB/s
| History: _____________X__+__
+------------------------------------------------------------------------------

+-- NETWORK -------------------------------------------------------------------
| Total:      5.89 KB/s | #########.........................................
| Sent:         561 B/s
| Received:   5.35 KB/s
| History: ..-____+..-....X#..
+------------------------------------------------------------------------------

Status: CPU:ON | MEM:ON | DISK:ON | NET:ON
```

### Processes View - All Sections (8 per section)

```
===============================================================================
            WINDOWS RESOURCE MONITOR - 2025-10-21 15:33:31 - PROCESSES VIEW
===============================================================================
Mode: [C]=CPU only | [M]=Memory only | [D]=Disk only | [N]=Network only | [A]=All sections | [SPACE]=Stats

+-- TOP PROCESSES BY CPU ------------------------------------------------------
| Name                               CPU(s)   Memory(MB)      PID
|------------------------------------------------------------------------------
| chrome                            125.45       856.23     1234
| code                               45.32       512.67     5678
| firefox                            32.18       678.90     9012
| explorer                           12.45       256.34     3456
| powershell                          5.67        89.12     7890
| system                              3.21       123.45        4
| dwm                                 2.15        45.67     1111
| msedge                              1.98       234.56     2222
+------------------------------------------------------------------------------

+-- TOP PROCESSES BY MEMORY ---------------------------------------------------
| Name                               CPU(s)  Private(MB)      PID
|------------------------------------------------------------------------------
[...8 processes...]
+------------------------------------------------------------------------------

[Similar sections for DISK and NETWORK]

Current Mode: ALL
```

### Processes View - CPU Only (30 processes)

```
===============================================================================
            WINDOWS RESOURCE MONITOR - 2025-10-21 15:33:31 - PROCESSES VIEW
===============================================================================
Mode: [C]=CPU only | [M]=Memory only | [D]=Disk only | [N]=Network only | [A]=All sections | [SPACE]=Stats

=== TOP PROCESSES BY CPU (Showing 30) ===

+------------------------------------------------------------------------------+
| Name                               CPU(s)   Memory(MB)      PID |
+------------------------------------------------------------------------------+
| chrome                            125.45       856.23     1234 |
| code                               45.32       512.67     5678 |
| firefox                            32.18       678.90     9012 |
| explorer                           12.45       256.34     3456 |
| powershell                          5.67        89.12     7890 |
| system                              3.21       123.45        4 |
| dwm                                 2.15        45.67     1111 |
| msedge                              1.98       234.56     2222 |
[...22 more processes...]
+------------------------------------------------------------------------------+

Current Mode: CPU
```

## Configuration

You can modify these variables at the top of the script:

```powershell
$RefreshInterval = 1        # Refresh rate in seconds
$GraphWidth = 50           # Width of the bar graphs
$HistorySize = 20          # Number of history points for sparkline
$MaxProcessDisplay = 30    # Maximum processes in single-resource mode
```

## Color Coding

- **CPU** - Yellow/Green
- **Memory** - Magenta/DarkCyan
- **Disk I/O** - Blue
- **Network** - Red
- **History Graphs** - Cyan
- **Status Bar** - DarkGray

## Process Information

### CPU View
- **CPU(s)** - Cumulative CPU time since process start
- **Memory(MB)** - Current working set in megabytes
- Sorted by highest CPU time

### Memory View
- **CPU(s)** - Cumulative CPU time
- **Private(MB)** - Private memory (not shared)
- Sorted by highest private memory usage

### Disk View
- **Disk I/O (B/s)** - Total bytes per second (read + write)
- Sorted by highest I/O activity

### Network View (Estimated)
- **Status** - Shows "Active" for processes likely using network
- **Memory(MB)** - Current working set
- Note: Windows doesn't provide direct per-process network stats

## Notes

- Running as Administrator provides more accurate metrics
- Make sure the PowerShell window has focus for keyboard shortcuts
- CPU times are cumulative since process start (not real-time %)
- Network per-process monitoring is estimated (Windows limitation)
- Single-resource mode shows up to 30 processes for detailed analysis
- All-sections mode shows 8 processes per section for quick overview

## Tips

### Effective Usage
1. **Start in Stats View** to see overall system health
2. **Press SPACE** to check top processes across all resources
3. **Press C/M/D/N** to focus on a specific bottleneck
4. **Press A** to return to all-sections view
5. **Press SPACE** to return to stats with graphs

### Troubleshooting System Issues
- **High CPU**: Press SPACE → C to see all CPU-intensive processes
- **Memory Issues**: Press SPACE → M to see memory hogs
- **Disk Slowness**: Press SPACE → D to see disk I/O culprits
- **Network Activity**: Press SPACE → N to see active processes

### Performance Monitoring
- Watch sparklines in Stats View for trends
- Use single-resource mode for detailed investigation
- Toggle stats sections off to focus on specific metrics

## Common Issues

**Keys not working:**
- Click on the PowerShell window to give it focus
- Make sure you're not in another application
- Try clicking and pressing the key again

**No processes shown:**
- Disk/Network counters may need Administrator privileges
- Run PowerShell as Administrator for full functionality

**Display issues:**
- Ensure terminal is at least 80 characters wide
- Use a monospace font (Consolas, Cascadia Code)
- Check if your terminal supports ANSI colors

## License

Free to use and modify as needed.