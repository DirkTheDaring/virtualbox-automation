# Introduction
Author Dietmar Kling
License: BSD

# Files

    etc/global.bat           Global Configuration, inherited by all config files
    etc/kickstart-templates/ Templates which are used to generate kickstart files
    etc/virtualbox/*.bat     Templates for virtual machines like fedora, centos..
    etc/user-preferences/    Contains user environment, automatically generated
    bin/                     Tools for generating a virtual machine
    iso/                     Contains iso images

# Remarks
* kickstart-templates contains only files with unix lf (.gitattributes makes sure that LF is maintained in windows)
* all other files will either have LF or CRLF depending on Windows or Linux.
* This enables to maintain these scripts also under a unix environment, without destroy anything 


Generate virtual files
You can provide a name for a virtual machine on the command line, otherwise
the a default name will be taken as default machine name.

coreos-server-setup.bat
centos-workstation-setup.bat
fedora-workstation-setup.bat
