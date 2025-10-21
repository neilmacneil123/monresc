<#
.SYNOPSIS
    Real-time Resource Monitor for Windows
.DESCRIPTION
    Displays CPU, Memory, Disk, and Network statistics with graphs and top processes
.NOTES
    Press Ctrl+C to exit
    Press SPACE to toggle between Stats and Processes view
    Press C, M, D, N to toggle individual sections (CPU, Memory, Disk, Network)
#>

# Set console to UTF-8 for proper character display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Configuration
$TopProcessCount = 8  # Base number of processes (dynamically adjusts)
$RefreshInterval = 1  # seconds - reduced for more responsive key detection
$GraphWidth = 50
$HistorySize = 20

# View state
$script:showProcesses = $false
$script:showCPU = $true
$script:showMemory = $true
$script:showDisk = $true
$script:showNetwork = $true

# Initialize history arrays
$cpuHistory = @()
$memHistory = @()
$diskHistory = @()
$netHistory = @()

# Store previous network counters
$previousNetBytes = 0
$previousTime = Get-Date

function Check-KeyPress {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            'Spacebar' {
                $script:showProcesses = -not $script:showProcesses
                return $true
            }
            'C' {
                $script:showCPU = -not $script:showCPU
                return $true
            }
            'M' {
                $script:showMemory = -not $script:showMemory
                return $true
            }
            'D' {
                $script:showDisk = -not $script:showDisk
                return $true
            }
            'N' {
                $script:showNetwork = -not $script:showNetwork
                return $true
            }
        }
    }
    return $false
}

function Get-CPUUsage {
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    return [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
}

function Get-MemoryUsage {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMem = $os.TotalVisibleMemorySize
    $freeMem = $os.FreePhysicalMemory
    $usedMem = $totalMem - $freeMem
    $percentUsed = [math]::Round(($usedMem / $totalMem) * 100, 1)
    
    return @{
        Percent = $percentUsed
        Used = [math]::Round($usedMem / 1MB, 2)
        Total = [math]::Round($totalMem / 1MB, 2)
    }
}

function Get-DiskUsage {
    try {
        $diskRead = (Get-Counter '\PhysicalDisk(_Total)\Disk Read Bytes/sec' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $diskWrite = (Get-Counter '\PhysicalDisk(_Total)\Disk Write Bytes/sec' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $totalDisk = $diskRead + $diskWrite
        
        return @{
            Total = [math]::Round($totalDisk, 0)
            Read = [math]::Round($diskRead, 0)
            Write = [math]::Round($diskWrite, 0)
        }
    }
    catch {
        return @{
            Total = 0
            Read = 0
            Write = 0
        }
    }
}

function Get-NetworkUsage {
    param($previousBytes, $previousTime)
    
    try {
        $currentTime = Get-Date
        $timeDiff = ($currentTime - $previousTime).TotalSeconds
        
        if ($timeDiff -eq 0) { $timeDiff = 1 }
        
        $netSent = (Get-Counter '\Network Interface(*)\Bytes Sent/sec' -ErrorAction SilentlyContinue).CounterSamples | 
            Where-Object { $_.InstanceName -notmatch 'isatap|Teredo' } | 
            Measure-Object -Property CookedValue -Sum | 
            Select-Object -ExpandProperty Sum
            
        $netRecv = (Get-Counter '\Network Interface(*)\Bytes Received/sec' -ErrorAction SilentlyContinue).CounterSamples | 
            Where-Object { $_.InstanceName -notmatch 'isatap|Teredo' } | 
            Measure-Object -Property CookedValue -Sum | 
            Select-Object -ExpandProperty Sum
        
        $totalNet = $netSent + $netRecv
        
        return @{
            Total = [math]::Round($totalNet, 0)
            Sent = [math]::Round($netSent, 0)
            Received = [math]::Round($netRecv, 0)
            Time = $currentTime
        }
    }
    catch {
        return @{
            Total = 0
            Sent = 0
            Received = 0
            Time = Get-Date
        }
    }
}

function Format-Bytes {
    param([double]$bytes)
    
    if ($bytes -ge 1GB) {
        return "{0:N2} GB/s" -f ($bytes / 1GB)
    }
    elseif ($bytes -ge 1MB) {
        return "{0:N2} MB/s" -f ($bytes / 1MB)
    }
    elseif ($bytes -ge 1KB) {
        return "{0:N2} KB/s" -f ($bytes / 1KB)
    }
    else {
        return "{0:N0} B/s" -f $bytes
    }
}

function Draw-Graph {
    param(
        [array]$history,
        [int]$width,
        [double]$maxValue = 100
    )
    
    if ($history.Count -eq 0) {
        return "#" * $width
    }
    
    $latest = $history[-1]
    $filled = [math]::Round(($latest / $maxValue) * $width)
    $filled = [math]::Min($filled, $width)
    $empty = $width - $filled
    
    $bar = ("#" * $filled) + ("." * $empty)
    return $bar
}

function Draw-SparkLine {
    param(
        [array]$history,
        [int]$width,
        [double]$maxValue = 100
    )
    
    if ($history.Count -eq 0) {
        return " " * $width
    }
    
    $chars = @("_", ".", "-", "=", "+", "*", "#", "@", "X")
    $result = ""
    
    $pointsToShow = [math]::Min($history.Count, $width)
    $startIndex = [math]::Max(0, $history.Count - $width)
    
    for ($i = $startIndex; $i -lt $history.Count; $i++) {
        $value = $history[$i]
        $normalized = ($value / $maxValue) * ($chars.Count - 1)
        $index = [math]::Min([math]::Round($normalized), $chars.Count - 1)
        $result += $chars[$index]
    }
    
    # Pad if needed
    while ($result.Length -lt $width) {
        $result = " " + $result
    }
    
    return $result
}

function Get-TopProcessesByCPU {
    param([int]$count)
    
    Get-Process | 
        Where-Object { $_.CPU -ne $null } |
        Sort-Object CPU -Descending | 
        Select-Object -First $count |
        Select-Object Name, 
            @{Name='CPU';Expression={[math]::Round($_.CPU, 2)}},
            @{Name='Memory(MB)';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
            Id
}

function Get-TopProcessesByMemory {
    param([int]$count)
    
    Get-Process | 
        Where-Object { $_.WorkingSet64 -gt 0 } |
        Sort-Object PrivateMemorySize64 -Descending | 
        Select-Object -First $count |
        Select-Object Name, 
            @{Name='CPU';Expression={[math]::Round($_.CPU, 2)}},
            @{Name='Private(MB)';Expression={[math]::Round($_.PrivateMemorySize64 / 1MB, 2)}},
            Id
}

function Get-TopProcessesByDisk {
    param([int]$count)
    
    try {
        $processes = Get-Counter '\Process(*)\IO Data Bytes/sec' -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty CounterSamples |
            Where-Object { $_.InstanceName -ne '_total' -and $_.InstanceName -ne 'idle' } |
            Sort-Object CookedValue -Descending |
            Select-Object -First $count |
            Select-Object @{Name='Name';Expression={$_.InstanceName}},
                          @{Name='DiskIO(B/s)';Expression={[math]::Round($_.CookedValue, 0)}},
                          @{Name='PID';Expression={
                              try {
                                  (Get-Process -Name $_.InstanceName -ErrorAction SilentlyContinue | Select-Object -First 1).Id
                              } catch { 0 }
                          }}
        return $processes
    }
    catch {
        return @()
    }
}

function Get-TopProcessesByNetwork {
    param([int]$count)
    
    try {
        # Network per-process monitoring is limited, using total I/O as proxy
        $processes = Get-Process | 
            Where-Object { $_.Id -ne 0 -and $_.Id -ne 4 } |
            Sort-Object { $_.WorkingSet64 } -Descending |
            Select-Object -First $count |
            Select-Object Name,
                @{Name='Network(Est)';Expression={'Active'}},
                @{Name='Memory(MB)';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
                Id
        return $processes
    }
    catch {
        return @()
    }
}

function Clear-Screen {
    Clear-Host
    [Console]::CursorVisible = $false
}

function Get-VisibleSectionCount {
    $count = 0
    if ($script:showCPU) { $count++ }
    if ($script:showMemory) { $count++ }
    if ($script:showDisk) { $count++ }
    if ($script:showNetwork) { $count++ }
    return $count
}

function Get-DynamicProcessCount {
    $visibleSections = Get-VisibleSectionCount
    # Adjust process count based on available screen space
    switch ($visibleSections) {
        0 { return 20 }
        1 { return 15 }
        2 { return 10 }
        default { return 8 }
    }
}

# Main loop
Write-Host "Starting Resource Monitor..." -ForegroundColor Cyan
Write-Host "Controls: SPACE=Toggle View | C=CPU | M=Memory | D=Disk | N=Network | Ctrl+C=Exit" -ForegroundColor Yellow
Write-Host "TIP: Make sure this window has focus for keyboard controls to work!" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 2

try {
    while ($true) {
        # Check for key presses
        Check-KeyPress | Out-Null
        
        # Collect metrics
        $cpuUsage = Get-CPUUsage
        $memUsage = Get-MemoryUsage
        $diskUsage = Get-DiskUsage
        $netUsage = Get-NetworkUsage -previousBytes $previousNetBytes -previousTime $previousTime
        
        # Update history
        $cpuHistory += $cpuUsage
        $memHistory += $memUsage.Percent
        $diskHistory += $diskUsage.Total
        $netHistory += $netUsage.Total
        
        # Trim history
        if ($cpuHistory.Count -gt $HistorySize) { $cpuHistory = $cpuHistory[-$HistorySize..-1] }
        if ($memHistory.Count -gt $HistorySize) { $memHistory = $memHistory[-$HistorySize..-1] }
        if ($diskHistory.Count -gt $HistorySize) { $diskHistory = $diskHistory[-$HistorySize..-1] }
        if ($netHistory.Count -gt $HistorySize) { $netHistory = $netHistory[-$HistorySize..-1] }
        
        # Calculate max values for graphs
        $maxDisk = if ($diskHistory.Count -gt 0) { ($diskHistory | Measure-Object -Maximum).Maximum } else { 1 }
        $maxNet = if ($netHistory.Count -gt 0) { ($netHistory | Measure-Object -Maximum).Maximum } else { 1 }
        if ($maxDisk -eq 0) { $maxDisk = 1 }
        if ($maxNet -eq 0) { $maxNet = 1 }
        
        # Get dynamic process count and visible section count
        $dynamicProcessCount = Get-DynamicProcessCount
        $visibleSections = Get-VisibleSectionCount
        
        # Clear screen and display
        Clear-Screen
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "===============================================================================" -ForegroundColor Cyan
        $modeText = if ($script:showProcesses) { "PROCESSES VIEW" } else { "STATS VIEW" }
        Write-Host "            WINDOWS RESOURCE MONITOR - $timestamp - $modeText" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "Controls: [SPACE]=Toggle | [C]=CPU | [M]=Memory | [D]=Disk | [N]=Network" -ForegroundColor DarkGray
        
        # Show process count info in processes view
        if ($script:showProcesses) {
            Write-Host "Showing $dynamicProcessCount processes per section ($visibleSections sections visible)" -ForegroundColor DarkGray
        }
        Write-Host ""
        
        if (-not $script:showProcesses) {
            # Stats View - Show system metrics
            
            if ($script:showCPU) {
                # CPU Section
                Write-Host "+-- CPU USAGE " -NoNewline -ForegroundColor Green
                Write-Host ("-" * 65) -ForegroundColor Green
                Write-Host "| Current: " -NoNewline -ForegroundColor White
                Write-Host ("{0,5}%" -f $cpuUsage) -NoNewline -ForegroundColor Yellow
                Write-Host " | " -NoNewline -ForegroundColor Green
                Write-Host (Draw-Graph -history $cpuHistory -width $GraphWidth -maxValue 100) -ForegroundColor Green
                Write-Host "| History: " -NoNewline -ForegroundColor White
                Write-Host (Draw-SparkLine -history $cpuHistory -width $GraphWidth -maxValue 100) -ForegroundColor Cyan
                Write-Host ("+" + ("-" * 78)) -ForegroundColor Green
                Write-Host ""
            }
            
            if ($script:showMemory) {
                # Memory Section
                Write-Host "+-- MEMORY USAGE " -NoNewline -ForegroundColor Magenta
                Write-Host ("-" * 62) -ForegroundColor Magenta
                Write-Host "| Current: " -NoNewline -ForegroundColor White
                Write-Host ("{0,5}%" -f $memUsage.Percent) -NoNewline -ForegroundColor Yellow
                Write-Host " | " -NoNewline -ForegroundColor Magenta
                Write-Host (Draw-Graph -history $memHistory -width $GraphWidth -maxValue 100) -ForegroundColor Magenta
                Write-Host "| Used:    " -NoNewline -ForegroundColor White
                Write-Host ("{0:N2} GB" -f $memUsage.Used) -NoNewline -ForegroundColor Yellow
                Write-Host " / " -NoNewline -ForegroundColor White
                Write-Host ("{0:N2} GB" -f $memUsage.Total) -ForegroundColor Yellow
                Write-Host "| History: " -NoNewline -ForegroundColor White
                Write-Host (Draw-SparkLine -history $memHistory -width $GraphWidth -maxValue 100) -ForegroundColor Cyan
                Write-Host ("+" + ("-" * 78)) -ForegroundColor Magenta
                Write-Host ""
            }
            
            if ($script:showDisk) {
                # Disk Section
                Write-Host "+-- DISK I/O " -NoNewline -ForegroundColor Blue
                Write-Host ("-" * 66) -ForegroundColor Blue
                Write-Host "| Total:   " -NoNewline -ForegroundColor White
                Write-Host ("{0,15}" -f (Format-Bytes $diskUsage.Total)) -NoNewline -ForegroundColor Yellow
                Write-Host " | " -NoNewline -ForegroundColor Blue
                Write-Host (Draw-Graph -history $diskHistory -width $GraphWidth -maxValue $maxDisk) -ForegroundColor Blue
                Write-Host "| Read:    " -NoNewline -ForegroundColor White
                Write-Host ("{0,15}" -f (Format-Bytes $diskUsage.Read)) -ForegroundColor Yellow
                Write-Host "| Write:   " -NoNewline -ForegroundColor White
                Write-Host ("{0,15}" -f (Format-Bytes $diskUsage.Write)) -ForegroundColor Yellow
                Write-Host "| History: " -NoNewline -ForegroundColor White
                Write-Host (Draw-SparkLine -history $diskHistory -width $GraphWidth -maxValue $maxDisk) -ForegroundColor Cyan
                Write-Host ("+" + ("-" * 78)) -ForegroundColor Blue
                Write-Host ""
            }
            
            if ($script:showNetwork) {
                # Network Section
                Write-Host "+-- NETWORK " -NoNewline -ForegroundColor Red
                Write-Host ("-" * 67) -ForegroundColor Red
                Write-Host "| Total:   " -NoNewline -ForegroundColor White
                Write-Host ("{0,15}" -f (Format-Bytes $netUsage.Total)) -NoNewline -ForegroundColor Yellow
                Write-Host " | " -NoNewline -ForegroundColor Red
                Write-Host (Draw-Graph -history $netHistory -width $GraphWidth -maxValue $maxNet) -ForegroundColor Red
                Write-Host "| Sent:    " -NoNewline -ForegroundColor White
                Write-Host ("{0,15}" -f (Format-Bytes $netUsage.Sent)) -ForegroundColor Yellow
                Write-Host "| Received:" -NoNewline -ForegroundColor White
                Write-Host ("{0,15}" -f (Format-Bytes $netUsage.Received)) -ForegroundColor Yellow
                Write-Host "| History: " -NoNewline -ForegroundColor White
                Write-Host (Draw-SparkLine -history $netHistory -width $GraphWidth -maxValue $maxNet) -ForegroundColor Cyan
                Write-Host ("+" + ("-" * 78)) -ForegroundColor Red
                Write-Host ""
            }
        }
        else {
            # Processes View - Show top processes for enabled sections
            
            if ($script:showCPU) {
                Write-Host "+-- TOP PROCESSES BY CPU " -NoNewline -ForegroundColor Yellow
                Write-Host ("-" * 54) -ForegroundColor Yellow
                $topCPU = Get-TopProcessesByCPU -count $dynamicProcessCount
                Write-Host ("| {0,-30} {1,10} {2,12} {3,8}" -f "Name", "CPU(s)", "Memory(MB)", "PID") -ForegroundColor White
                Write-Host "|" -NoNewline -ForegroundColor Yellow
                Write-Host ("-" * 78) -ForegroundColor DarkGray
                foreach ($proc in $topCPU) {
                    Write-Host "| " -NoNewline -ForegroundColor Yellow
                    Write-Host ("{0,-30}" -f $proc.Name.Substring(0, [math]::Min(30, $proc.Name.Length))) -NoNewline -ForegroundColor White
                    Write-Host ("{0,10:N2}" -f $proc.CPU) -NoNewline -ForegroundColor Green
                    Write-Host ("{0,12:N2}" -f $proc.'Memory(MB)') -NoNewline -ForegroundColor Cyan
                    Write-Host ("{0,8}" -f $proc.Id) -ForegroundColor Gray
                }
                Write-Host ("+" + ("-" * 78)) -ForegroundColor Yellow
                Write-Host ""
            }
            else {
                Write-Host "+-- TOP PROCESSES BY CPU [HIDDEN - Press C to show] " -NoNewline -ForegroundColor DarkGray
                Write-Host ("-" * 27) -ForegroundColor DarkGray
                Write-Host ""
            }
            
            if ($script:showMemory) {
                Write-Host "+-- TOP PROCESSES BY MEMORY " -NoNewline -ForegroundColor DarkCyan
                Write-Host ("-" * 51) -ForegroundColor DarkCyan
                $topMem = Get-TopProcessesByMemory -count $dynamicProcessCount
                Write-Host ("| {0,-30} {1,10} {2,12} {3,8}" -f "Name", "CPU(s)", "Private(MB)", "PID") -ForegroundColor White
                Write-Host "|" -NoNewline -ForegroundColor DarkCyan
                Write-Host ("-" * 78) -ForegroundColor DarkGray
                foreach ($proc in $topMem) {
                    Write-Host "| " -NoNewline -ForegroundColor DarkCyan
                    Write-Host ("{0,-30}" -f $proc.Name.Substring(0, [math]::Min(30, $proc.Name.Length))) -NoNewline -ForegroundColor White
                    Write-Host ("{0,10:N2}" -f $proc.CPU) -NoNewline -ForegroundColor Green
                    Write-Host ("{0,12:N2}" -f $proc.'Private(MB)') -NoNewline -ForegroundColor Magenta
                    Write-Host ("{0,8}" -f $proc.Id) -ForegroundColor Gray
                }
                Write-Host ("+" + ("-" * 78)) -ForegroundColor DarkCyan
                Write-Host ""
            }
            else {
                Write-Host "+-- TOP PROCESSES BY MEMORY [HIDDEN - Press M to show] " -NoNewline -ForegroundColor DarkGray
                Write-Host ("-" * 23) -ForegroundColor DarkGray
                Write-Host ""
            }
            
            if ($script:showDisk) {
                Write-Host "+-- TOP PROCESSES BY DISK I/O " -NoNewline -ForegroundColor Blue
                Write-Host ("-" * 48) -ForegroundColor Blue
                $topDisk = Get-TopProcessesByDisk -count $dynamicProcessCount
                if ($topDisk.Count -gt 0) {
                    Write-Host ("| {0,-40} {1,15} {2,8}" -f "Name", "Disk I/O (B/s)", "PID") -ForegroundColor White
                    Write-Host "|" -NoNewline -ForegroundColor Blue
                    Write-Host ("-" * 78) -ForegroundColor DarkGray
                    foreach ($proc in $topDisk) {
                        Write-Host "| " -NoNewline -ForegroundColor Blue
                        Write-Host ("{0,-40}" -f $proc.Name.Substring(0, [math]::Min(40, $proc.Name.Length))) -NoNewline -ForegroundColor White
                        Write-Host ("{0,15:N0}" -f $proc.'DiskIO(B/s)') -NoNewline -ForegroundColor Yellow
                        Write-Host ("{0,8}" -f $proc.PID) -ForegroundColor Gray
                    }
                }
                else {
                    Write-Host "| No disk I/O data available" -ForegroundColor Gray
                }
                Write-Host ("+" + ("-" * 78)) -ForegroundColor Blue
                Write-Host ""
            }
            else {
                Write-Host "+-- TOP PROCESSES BY DISK I/O [HIDDEN - Press D to show] " -NoNewline -ForegroundColor DarkGray
                Write-Host ("-" * 21) -ForegroundColor DarkGray
                Write-Host ""
            }
            
            if ($script:showNetwork) {
                Write-Host "+-- TOP PROCESSES BY NETWORK (Estimated) " -NoNewline -ForegroundColor Red
                Write-Host ("-" * 37) -ForegroundColor Red
                $topNet = Get-TopProcessesByNetwork -count $dynamicProcessCount
                Write-Host ("| {0,-30} {1,15} {2,12} {3,8}" -f "Name", "Status", "Memory(MB)", "PID") -ForegroundColor White
                Write-Host "|" -NoNewline -ForegroundColor Red
                Write-Host ("-" * 78) -ForegroundColor DarkGray
                foreach ($proc in $topNet) {
                    Write-Host "| " -NoNewline -ForegroundColor Red
                    Write-Host ("{0,-30}" -f $proc.Name.Substring(0, [math]::Min(30, $proc.Name.Length))) -NoNewline -ForegroundColor White
                    Write-Host ("{0,15}" -f $proc.'Network(Est)') -NoNewline -ForegroundColor Green
                    Write-Host ("{0,12:N2}" -f $proc.'Memory(MB)') -NoNewline -ForegroundColor Cyan
                    Write-Host ("{0,8}" -f $proc.Id) -ForegroundColor Gray
                }
                Write-Host ("+" + ("-" * 78)) -ForegroundColor Red
                Write-Host ""
            }
            else {
                Write-Host "+-- TOP PROCESSES BY NETWORK [HIDDEN - Press N to show] " -NoNewline -ForegroundColor DarkGray
                Write-Host ("-" * 22) -ForegroundColor DarkGray
                Write-Host ""
            }
        }
        
        # Status bar
        $statusParts = @()
        if ($script:showCPU) { $statusParts += "CPU:ON" } else { $statusParts += "CPU:OFF" }
        if ($script:showMemory) { $statusParts += "MEM:ON" } else { $statusParts += "MEM:OFF" }
        if ($script:showDisk) { $statusParts += "DISK:ON" } else { $statusParts += "DISK:OFF" }
        if ($script:showNetwork) { $statusParts += "NET:ON" } else { $statusParts += "NET:OFF" }
        $statusBar = $statusParts -join " | "
        Write-Host "Status: $statusBar" -ForegroundColor DarkGray
        
        # Update previous network values
        $previousNetBytes = $netUsage.Total
        $previousTime = $netUsage.Time
        
        Start-Sleep -Seconds $RefreshInterval
    }
}
finally {
    [Console]::CursorVisible = $true
    Write-Host "`nResource Monitor stopped." -ForegroundColor Cyan
}