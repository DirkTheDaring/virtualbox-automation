@echo off

REM Get Filename of current bat file
SET BATFILENAME=%~F0

REM Cut off .bat extension
SET PREFIX=%BATFILENAME:~0,-4%

REM Create Name of CScript
SET CSCRIPTNAME=%PREFIX%.vbs

REM Execute the CScript
c:\windows\system32\cscript //nologo "%CSCRIPTNAME%" %*