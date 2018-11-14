Option Explicit
' Author: Dietmar Kling
' Written 2006-2016
' Options
' /r use regular expresson for search
' /o:filename   write output to filename
' /u use unix file end LF (chr(10)) if you write to file


Main(WScript.Arguments)
WScript.Quit(0)

Function Main(args)
  Dim fso
  Dim filename
  Dim oldstr
  Dim newstr
  Dim file
  Dim line
  Dim regex
  Dim useRegex
  Dim outputFilename
  Dim outputFile
  Dim endOfLine
  Dim i
  Dim adodbStreamIn
  Dim adodbStreamOut

  Const adReadLine = -2


  If args.Unnamed.Count < 3 Then
    WScript.Echo "repl [options] filename oldstr newstr oldstr2 newstr2 ..."
    WScript.Quit(0)
  End If

  ' /r to use an regular search expression
  useRegex = args.Named.Exists("r")

  If args.Named.Exists("o") Then
    outputFilename = args.Named("o")
  End If

  ' Dos Line ending
  endOfLine = chr(13) & chr(10)

  ' Unix End Of Line
  If args.Named.Exists("u") Then
    endOfLine = chr(10)
  End If

  filename = args.Unnamed(0)

  If useRegex Then
    Set regex = New RegExp
	
  End If

  Set fso         = CreateObject("Scripting.FileSystemObject")
  Set adodbStreamIn  = CreateObject("ADODB.Stream")
  Set adodbStreamOut = CreateObject("ADODB.Stream")

  If Not fso.FileExists(filename) Then
    WScript.Echo "FILE DOES NOT EXIST: " & filename
    WScript.Quit(1)
  End If

  adodbStreamIn.CharSet = "utf-8"
  adodbStreamIn.Open
  adodbStreamIn.LoadFromFile(filename)

  If Not outputFilename = "" Then
     adodbStreamOut.CharSet = "utf-8"
     adodbStreamOut.Open

  End If

  Do Until adodbStreamIn.EOS
    line = adodbStreamIn.ReadText(adReadLine)

	i=1
	While i < args.Unnamed.Count
	  oldstr = args.Unnamed(i)
          newstr = args.Unnamed(i+1)
	  i = i + 2
	
	  If useRegex Then
		regex.Pattern = oldstr
	    line = regex.Replace(line, newstr)
	  Else
	    line = Replace(line,oldstr,newstr)
	  End If
	
	Wend
		
    If outputFilename = "" Then
      WScript.Echo line
    Else
       adodbStreamOut.WriteText line & chr(10)
    End If

  Loop

  If Not outputFilename = "" Then
    adodbStreamOut.SaveToFile outputFilename,2
    adodbStreamOut.Close
  End If

  adodbStreamIn.Close

End Function
