Option Explicit
' Written by Dietmar Kling 

Main(WScript.Arguments)
WScript.Quit(0)

Function GetDomainController()
  Dim objDomain
  Dim dnsHostName

  Set objDomain = GetObject("LDAP://rootDse")
    dnsHostName = objDomain.Get("dnsHostName")

  GetDomainController = dnsHostName
End Function

Function Main(args)
  Dim result,is_shell

  is_shell  = args.Named.Exists("shell")
     result = GetDomainController()

  If is_shell Then
    WScript.Echo "SET DOMAIN_CONTROLLER=" & result
  Else
    WScript.Echo result
  End If

End Function
