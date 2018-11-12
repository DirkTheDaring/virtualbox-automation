@ECHO OFF
SET VIRTUALBOX_HOME_DIR=%~1

IF NOT "%VIRTUALBOX_VM_DIR%" == "" GOTO print_vm_dir

IF EXIST "%VIRTUALBOX_HOME_DIR%" GOTO continue_process_2
  ECHO VIRTUALBOX_HOME_DIR DOES NOT EXIST: %VIRTUALBOX_HOME_DIR% 1>&2
  EXIT /B 1
:continue_process_2
REM echo %VIRTUALBOX_HOME_DIR%
FOR /f "delims= usebackq tokens=1" %%a IN (`"%VIRTUALBOX_HOME_DIR%\vboxmanage" list systemproperties ^| findstr /r /c:^Default.machine.folder:`) do SET RESULT=%%a
SET VIRTUALBOX_VM_DIR=%RESULT:~23%
FOR /f "tokens=*" %%s IN ("%VIRTUALBOX_VM_DIR%") DO (SET VIRTUALBOX_VM_DIR=%%s)

:print_vm_dir
ECHO %VIRTUALBOX_VM_DIR%
