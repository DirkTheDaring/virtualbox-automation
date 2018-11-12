Option Explicit
Main(WScript.Arguments)
WScript.Quit(0)

Function GetLDAPDN()
  Dim oTranslate
  Dim oNetwork
  Dim result

  Set oTranslate = CreateObject("NameTranslate")
  Set   oNetwork = CreateObject("WScript.Network")
  oTranslate.Init 3,""
  oTranslate.Set 3, oNetwork.UserDomain & "\" & oNetwork.UserName
  result = oTranslate.Get(1)

  GetLDAPDN=result
End Function

Function Main(args)
  Dim result
  Dim pos,postfix,ou,dc,only_postfix,only_dc,only_ou,is_shell,domain

  
  is_shell     = args.Named.Exists("shell")
  only_postfix = args.Named.Exists("postfix")
       only_dc = args.Named.Exists("dc")
       only_ou = args.Named.Exists("ou")

  result = GetLDAPDN()
  
  pos     = InStr(result, ",")
  postfix = Right(result, len(result)-pos)
  pos     = Instr(postfix,",DC=")
  ou      = Left(postfix, pos - 1)
  dc      = Right(postfix,len(postfix)-pos)
  domain  = Replace(dc,",DC=",".")
  domain  = Replace(domain,"DC=","")
  domain  = UCase(domain)

  If is_shell Then
    WScript.Echo "SET LDAP_OU="      & ou
    WScript.Echo "SET LDAP_BASE="  & dc
    WScript.Echo "SET LDAP_SEARCHBASE=" & postfix
    WScript.Echo "SET LDAP_DN="      & result
    WScript.Echo "SET LDAP_DOMAIN="  & domain

  Else
    WScript.Echo result
  End If

End Function
