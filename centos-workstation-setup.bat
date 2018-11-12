@ECHO OFF
SETLOCAL EnableExtensions

SET VM_TEMPLATE=centos-workstation
SET     VM_NAME=CentosWorkstation

IF NOT "%1" == "" SET VM_NAME=%1

SET SCRIPT_DIR=%~dp0
SET SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

%SCRIPT_DIR%\bin\virtualbox-setup %VM_TEMPLATE% %VM_NAME%
