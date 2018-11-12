'Use Explicit

Set sysInfo    = CreateObject("ADSystemInfo")
Set wshNetwork = CreateObject("WScript.Network")
' WScript.Echo wshNetwork.ComputerName & "." & sysInfo.DomainDNSName
WScript.Echo "SET HOSTNAME="  & LCase(wshNetwork.ComputerName) & "." & sysInfo.DomainDNSName
WScript.Echo "SET DNSDOMAIN=" & sysInfo.DomainDNSName
WScript.Echo "SET DOMAIN="    & UCase(sysInfo.DomainDNSName)


