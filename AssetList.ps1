# 1. Define your target computers here (comma-separated list)
$Computers = Get-Content -Path "C:\Users\sammy.wangai\Documents\comp.csv"

# 2. Configure the DCOM connection option
$SessionOption = New-CimSessionOption -Protocol Dcom

# 3. Process each computer
$Report = foreach ($Computer in $Computers) {
    try {
        # Establish DCOM session with a 5-second timeout so offline PCs don't hang the script
        $CimSession = New-CimSession -ComputerName $Computer -SessionOption $SessionOption -OperationTimeoutSec 5 -ErrorAction Stop
        
        # Gather System Specs
        $Bios = Get-CimInstance -ClassName Win32_Bios -CimSession $CimSession -ErrorAction Stop
        $Memory = Get-CimInstance -ClassName Win32_PhysicalMemory -CimSession $CimSession -ErrorAction Stop
        $Disks = Get-CimInstance -Namespace "Root\Microsoft\Windows\Storage" -ClassName MSFT_PhysicalDisk -CimSession $CimSession -ErrorAction Stop
        
        # NEW: Gather Computer System and OS details
        $CompSys = Get-CimInstance -ClassName Win32_ComputerSystem -CimSession $CimSession -ErrorAction Stop
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $CimSession -ErrorAction Stop
        
        # Calculate RAM
        $TotalRAM_GB = [Math]::Round(($Memory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 0)
        
        # NEW: Determine the active user OR fall back to the last user profile modified
        $LoggedUser = $CompSys.UserName
        if ([string]::IsNullOrEmpty($LoggedUser)) {
            # Bypasses blank active sessions by looking at the last modified user directory
            $LatestProfile = Get-CimInstance -ClassName Win32_UserProfile -CimSession $CimSession | 
                             Where-Object { $_.Special -eq $false -and $_.LocalPath -like "*\Users\*" } | 
                             Sort-Object LastUseTime -Descending | Select-Object -First 1
            if ($LatestProfile) {
                $LoggedUser = $LatestProfile.LocalPath.Split('\')[-1] + " (Last Logged)"
            } else {
                $LoggedUser = "None"
            }
        }
        
        # Output data for each physical disk found
        foreach ($Disk in $Disks) {
            [PSCustomObject]@{
                ComputerName = $Computer
                Status       = "Online"
                Model        = $CompSys.Model       # Added Model
                OperatingSys = $OS.Caption         # Added OS
                LoggedUser   = $LoggedUser          # Added User
                SerialNumber = $Bios.SerialNumber
                TotalRAM     = "$TotalRAM_GB GB"
                DriveModel   = $Disk.Model
                DriveSize    = "$([Math]::Round($Disk.Size / 1GB, 0)) GB"
                DriveType    = switch($Disk.MediaType) { 3 {'HDD'} 4 {'SSD'} 5 {'SCM'} Default {'Unknown'} }
            }
        }
        
        # Close the individual session
        Remove-CimSession -CimSession $CimSession
    }
    catch {
        # If a machine is offline or access is denied, report the error cleanly
        [PSCustomObject]@{
            ComputerName = $Computer
            Status       = "Offline / Error Connecting"
            Model        = "N/A"
            OperatingSys = "N/A"
            LoggedUser   = "N/A"
            SerialNumber = "N/A"
            TotalRAM     = "N/A"
            DriveModel   = "N/A"
            DriveSize    = "N/A"
            DriveType    = "N/A"
        }
    }
}

# 4. Display the results in a clean table format
$Report | Export-Csv -Path "C:\Users\sammy.wangai\Downloads\report.csv" -NoTypeInformation
