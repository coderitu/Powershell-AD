 Get-WmiObject -Class MSFT_PhysicalDisk -Namespace root\Microsoft\Windows\Storage -credential <#admin login credential#> -computername <#Computer name to be used#>  | Select PSComputerName, MediaType


## this powershell script gives you the type of hard drive(HDD/SSD) in a device connected to the domain remotely
#3 == HDD
#4 == SSD

#You can also use comma(,) to lookup several computers


#Result
#PSComputerName MediaType
#-------------- ---------
#MMORRIS450G1           3
#VICTOR430G2            4
