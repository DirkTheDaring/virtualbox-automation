REM @ECHO OFF

REM Registry Path where we can detect the installdir

SET REG_PATH=HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\VirtualBox
SET REG_KEY=InstallDir

REM Global settings for a VM ( aka "factory defaults")

SET OS_TYPE=Fedora_64
SET VM_IMAGE_SIZE_MB=25000
SET VM_RAM_SIZE_MB=1024
SET VM_VRAM_SIZE_MB=16
SET VM_CPUS=1

REM Download URLs

SET FEDORA_SERVER_URL=https://download.fedoraproject.org/pub/fedora/linux/releases/29/Server/x86_64/iso/Fedora-Server-dvd-x86_64-29-1.2.iso
SET CENTOS_SERVER_URL=http://ftp.wrz.de/pub/CentOS/7.5.1804/isos/x86_64/CentOS-7-x86_64-Everything-1804.iso
SET COREOS_SERVER_URL=https://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso

REM Global Default Image

SET DEFAULT_IMAGE_URL=%FEDORA_SERVER_URL%

REM Folder where the ISO Image(s) will be downloaded

SET ISO_DIR=%ROOT_DIR%\iso
SET ETC_DIR=%ROOT_DIR%\etc
SET KICKSTART_DIR=%ETC_DIR%\kickstart-templates

REM LDAP Settings
SET LDAP_ATTRIBUTES=sAMAccountName,givenname,sn,mail,Department,telephoneNumber,uidNumber,gidNumber,msSFU30HomeDirectory


SET SHARED_FOLDER_NAME=Shared
SET SHARED_FOLDER_PATH=%ROOT_DIR%

