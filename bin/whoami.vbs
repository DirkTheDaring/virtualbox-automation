Option Explicit

' ADS_SCOPEENUM
Const ADS_SCOPE_BASE			= 0
Const ADS_SCOPE_ONELEVEL		= 1
Const ADS_SCOPE_SUBTREE 		= 2

Const ADS_CHASE_REFERRALS_NEVER		  = &H00
Const ADS_CHASE_REFERRALS_SUBORDINATE = &H20
Const ADS_CHASE_REFERRALS_EXTERNAL	  = &H40
Const ADS_CHASE_REFERRALS_ALWAYS 	  = &H60   ' &H20 + &H40


Dim outputFormat

Main(WScript.Arguments)
WScript.Quit(0)

Function Main(args)

	Dim oShell
	Dim userName
	Dim searchBase
	Dim attrs
	
	' searchBase = "DC=example,DC=com"
        '      attrs = "sAMAccountName,givenname,sn,mail,Department,telephoneNumber,uidNumber,gidNumber,msSFU30HomeDirectory"

	outputFormat = "txt"
	

    If args.Named.Exists("searchBase") Then
	  searchBase = args.Named("searchBase")
	End If
	
	If args.Named.Exists("attrs") Then
	  attrs = args.Named("attrs")
	End If

	' Global Dim for this variable
	If args.Named.Exists("format") Then
	  outputFormat = args.Named("format")
	End If
    
	'WScript.Echo searchBase
	'WScript.Echo attrs
	'WScript.Echo outputFormat
	
	Set oShell    = CreateObject("WScript.Shell")
	userName      = oShell.ExpandEnvironmentStrings("%USERNAME%")
	
	
	Call SearchByUid(searchBase,userName,attrs)

End Function


Function SearchByUid(searchBase,Uid,attrs)
	Dim sql
	

	sql = "SELECT " & attrs & " " _
		  & "FROM 'LDAP://" & searchBase & "' " _
		  & "WHERE sAMAccountName='" & Uid & "'"

	SearchByUid=Search(sql,attrs)
End Function



Function Search(sql, attrs)
	Dim objConnection
	Dim objCommand
	Dim objRecordSet
	Dim i


	Set objConnection = CreateObject("ADODB.Connection")
	Set objCommand    = CreateObject("ADODB.Command")

	objConnection.Provider = "ADSDSOObject"
	objConnection.Open "Active Directory Provider"

	Set objCommand.ActiveConnection = objConnection

	objCommand.Properties("Page Size")   	 = 1000
	objCommand.Properties("Searchscope") 	 = ADS_SCOPE_SUBTREE 
	objCommand.Properties("Chase referrals") = ADS_CHASE_REFERRALS_ALWAYS	' Search different forests

	objCommand.CommandText = sql

	
	On Error Resume Next
	
	Set objRecordSet = objCommand.Execute
	If Not err.Number = 0 Then 
		If outputFormat = "shell" Then 
   		  WScript.Echo "REM LDAP Command Execute Failed." 
		Else
   		  WScript.Echo "LDAP Command Execute Failed."
		End If
		WScript.Quit(1)
	End If

	On Error Goto 0

	If objRecordSet.EOF Then
		Search=False
		Exit Function
	End If

	objRecordSet.MoveFirst
		
	While Not objRecordSet.EOF
		PrintRecordSet objRecordSet,attrs 
		objRecordSet.MoveNext
	Wend

	
	Search=True
End Function

Function Pad(ByRef Text, ByVal Length)   
	Pad = Left(Text & Space(Length), Length) 
End Function 
 


Function PrintRecordSet(objRecordSet,attrs)

    Dim field_list 
	Dim name_list 
	Dim length
	Dim field_array
	Dim xname
	Dim value
	Dim name_array
	Dim i
	Dim field
	
	field_list = attrs
	name_list  = attrs

	field_array = split(field_list,",")
	name_array  = split(name_list,",")

	length = ubound(field_array)

	for i=0 to length
		field = field_array(i)
		xname  = name_array(i)
		value = "" & objRecordSet.Fields(field)
		If outputFormat = "txt" Then 
		  WScript.Echo Pad(xname,10) &  ": " & value
		ElseIf outputFormat = "shell" Then
		  WScript.Echo "SET " & UCase(xname) & "=" & value 
		End If
	Next

End Function
