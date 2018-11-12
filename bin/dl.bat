@ECHO OFF

SET        JOB=%1
SET LOCAL_NAME=%2
SET REMOTE_URL=%3

REM ECHO %JOB% %LOCAL_NAME% %REMOTE_URL%
IF NOT EXIST %LOCAL_NAME% GOTO continue_donwload
ECHO FILE EXISTS: %LOCAL_NAME%
EXIT /B 1
:continue_donwload
bitsadmin /reset
bitsadmin /create %JOB%
bitsadmin /SetPriority %JOB% HIGH
bitsadmin /SetSecurityFlags %JOB% 2305
bitsadmin /addfile %JOB% %REMOTE_URL% %LOCAL_NAME%
bitsadmin /resume %JOB%
bitsadmin /info %JOB% /verbose
:until_transfer_complete
timeout /t 1 >nul
bitsadmin /info %JOB% /verbose|find "PRIORITY"
bitsadmin /info %JOB% /verbose|find "STATE: TRANSFERRED"
IF NOT %ERRORLEVEL% EQU 0 goto until_transfer_complete
bitsadmin /complete %JOB%
