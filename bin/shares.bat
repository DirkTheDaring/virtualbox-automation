@ECHO OFF 
wmic path Win32_LogicalDisk Where DriveType="4" get DeviceID, ProviderName
