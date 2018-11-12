REM @ECHO OFF
SETLOCAL EnableExtensions

IF NOT "%1" == "" GOTO continue_process_2
ECHO vm template name is missing
EXIT /B 1
:continue_process_2
SET VM_TEMPLATE=%1
SET VM_NAME=%2
IF "%VM_NAME%" == "" SET VM_NAME=%VM%

SET SCRIPT_DIR=%~dp0
SET SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
SET SCRIPT_FILENAME=%~n0%~x0
SET SCRIPT_NAME=%~n0

FOR %%a IN (%SCRIPT_DIR%) DO SET "ROOT_DIR=%%~dpa"
SET ROOT_DIR=%ROOT_DIR:~0,-1%

SET ETC_DIR=%ROOT_DIR%\etc

SET MY_USER_PROFILE_DIR="%ETC_DIR%\user-settings"
SET MY_USER_PROFILE=%MY_USER_PROFILE_DIR%\%USERNAME%.bat

IF EXIST "%MY_USER_PROFILE_DIR%" GOTO SKIP_MKDIR_MY_USER_PROFILE_DIR
MD "%MY_USER_PROFILE_DIR%"
:SKIP_MKDIR_MY_USER_PROFILE_DIR

REM Som initial setting need to be generated and included
CALL %SCRIPT_DIR%\dn.bat /shell>%MY_USER_PROFILE%
CALL %SCRIPT_DIR%\dc.bat /shell>>%MY_USER_PROFILE%
CALL %MY_USER_PROFILE%

IF EXIST "%ETC_DIR%\global.bat"               CALL "%ETC_DIR%\global.bat"
IF EXIST "%ETC_DIR%\virtualbox\%VM_TEMPLATE%.bat" CALL "%ETC_DIR%\virtualbox\%VM_TEMPLATE%.bat"
IF "%ISO_DIR%" == ""            SET ISO_DIR=%SCRIPT_DIR%\..\iso

FOR %%i IN (%DEFAULT_IMAGE_URL%) DO (SET IMAGE_FILE=%ISO_DIR%\%%~nxi)


ECHO Download Image
CALL %SCRIPT_DIR%\dl.bat myDownloadJob "%IMAGE_FILE%" %DEFAULT_IMAGE_URL%

ECHO Dumping Settings
ECHO(
ECHO SET VM_TEMPLATE=%VM_TEMPLATE%>"%MY_USER_PROFILE%"
ECHO SET VM_NAME=%VM_NAME%>>"%MY_USER_PROFILE%"
ECHO Gather Shell User Information
ECHO SET USERNAME=%USERNAME%>>"%MY_USER_PROFILE%"
ECHO SET USERPROFILE=%USERPROFILE%>>"%MY_USER_PROFILE%"

ECHO(

ECHO Get VirtualBox HOME Dir
FOR /f "delims= usebackq tokens=1" %%a IN (`%SCRIPT_DIR%\registry-query-key.bat %REG_PATH% %REG_KEY%`) DO SET VIRTUALBOX_HOME_DIR=%%a
SET VIRTUALBOX_HOME_DIR=%VIRTUALBOX_HOME_DIR:~0,-1%

ECHO SET VIRTUALBOX_HOME_DIR=%VIRTUALBOX_HOME_DIR%>>"%MY_USER_PROFILE%"

ECHO Virtualbox VM Dir
FOR /f "delims= usebackq tokens=1" %%a IN (`%SCRIPT_DIR%\virtualbox-get-vm-dir "%VIRTUALBOX_HOME_DIR%"`) DO SET VIRTUALBOX_VM_DIR=%%a
ECHO SET VIRTUALBOX_VM_DIR=%VIRTUALBOX_VM_DIR%>>"%MY_USER_PROFILE%"

ECHO Active directory
CALL %SCRIPT_DIR%\whoami /attrs:%LDAP_ATTRIBUTES% /searchBase:%LDAP_SEARCHBASE% "/format:shell">>"%MY_USER_PROFILE%"
ECHO Domain Name
CALL %SCRIPT_DIR%\fqdn>>"%MY_USER_PROFILE%"
ECHO SET KICKSTART_TEMPLATE=%KICKSTART_TEMPLATE%>>"%MY_USER_PROFILE%"
ECHO SET IMAGE_FILE=%IMAGE_FILE%>>"%MY_USER_PROFILE%"

CALL "%MY_USER_PROFILE%"

SET LINE=user --groups='wheel,docker' --name='%SAMACCOUNTNAME%' --gecos='%GIVENNAME% %SN%' --uid=%UIDNUMBER% --gid=%GIDNUMBER%>>"%MY_USER_PROFILE%"
TYPE "%MY_USER_PROFILE%"
ECHO(
ECHO(
echo %LINE%

ECHO Mounted Shares
CALL %SCRIPT_DIR%\shares.bat >"%MY_USER_PROFILE_DIR%\%USERNAME%-shares.txt"

IF EXIST "%VIRTUALBOX_VM_DIR%" GOTO SKIP_MKDIR_VM_DIR
md  "%VIRTUALBOX_VM_DIR%"
:SKIP_MKDIR_VM_DIR

REM If an VM dir alreay exists stop
IF NOT EXIST "%VIRTUALBOX_VM_DIR%\%VM_NAME%" GOTO start_vm_creation
ECHO ERROR: Already exists: %VIRTUALBOX_VM_DIR%\%VM_NAME% 
EXIT /B 10

:start_vm_creation
echo Ready.
ECHO ON
REM Create dir
IF NOT EXIST "%VIRTUALBOX_VM_DIR%\%VM_NAME%" MD "%VIRTUALBOX_VM_DIR%\%VM_NAME%"

IF "%KICKSTART_TEMPLATE%" == "" GOTO skip_to_image_creation
IF NOT EXIST "%KICKSTART_TEMPLATE%" GOTO skip_to_image_creation

SET KICKSTART_FILE=%VIRTUALBOX_VM_DIR%\%VM_NAME%\kickstart.ks

CALL %SCRIPT_DIR%\repl.bat "/o:%KICKSTART_FILE%" /u /r "%KICKSTART_TEMPLATE%" "^#USER_PLACEHOLDER DO NOT DELETE.*" "%LINE%"  "^USER_NAME=.*$" "USER_NAME=%SAMACCOUNTNAME%" "^network[ |\t]+--hostname=.*$" "network --hostname=%HOSTNAME%" "KERBEROS_DOMAIN" "%LDAP_DOMAIN%" "KERBEROS_SERVER" "%DOMAIN_CONTROLLER%" "LDAP_SEARCHBASE" "%LDAP_SEARCHBASE%"


:skip_to_image_creation
SET PATH=%PATH%;%VIRTUALBOX_HOME_DIR%

vboxmanage createvm --name %VM_NAME% --ostype %OS_TYPE% --register
if %ERRORLEVEL% == 0 goto next_step
ECHO "vm create failed"
exit /b 1

:next_step
SET IMAGE=%VIRTUALBOX_VM_DIR%\%VM_NAME%\%VM_NAME%.vdi
REM vboxmanage closemedium disk "%IMAGE%" --deleteREM Create Kickstart file
ECHO ON
REM  Set the Virtual CD ROM as secondary master (port 1)
vboxmanage storagectl    %VM_NAME% --name "IDE" --add ide 
vboxmanage storageattach %VM_NAME% --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium "%IMAGE_FILE%"

vboxmanage createmedium disk --filename "%IMAGE%" --size %VM_IMAGE_SIZE_MB%
vboxmanage storagectl    %VM_NAME% --name "SATA" --add sata --controller IntelAHCI --portcount 1
vboxmanage storageattach %VM_NAME% --storagectl "SATA" --port 0 --device 0 --type hdd --medium "%IMAGE%"

vboxmanage modifyvm %VM_NAME% --cpus %VM_CPUS%
vboxmanage modifyvm %VM_NAME% --ioapic on
vboxmanage modifyvm %VM_NAME% --accelerate3d on 

REM Second Network adapter
vboxmanage modifyvm %VM_NAME% --nic2 intnet
vboxmanage modifyvm %VM_NAME% --nicpromisc2 allow-all

vboxmanage modifyvm %VM_NAME% --memory %VM_RAM_SIZE_MB% --vram %VM_VRAM_SIZE_MB%

vboxmanage sharedfolder add %VM_NAME% --name %SHARED_FOLDER_NAME% --hostpath "%SHARED_FOLDER_PATH%" --automount

IF NOT "%KICKSTART_FILE%" == "" GOTO unattended_install
EXIT /b 0
:unattended_install

IF EXIST "%KICKSTART_FILE%" GOTO start_unattended_install
ECHO kickstart file not found: %KICKSTART_FILE%
EXIT /b 11
:start_unattended_install

vboxmanage unattended install %VM_NAME% "--iso=%IMAGE_FILE%" "--script-template=%KICKSTART_FILE%"
vboxmanage startvm %VM_NAME%

echo "Done."
