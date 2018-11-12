#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
cdrom
# use text install
text 
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate
network  --bootproto=dhcp --device=enp0s8 --onboot=off --ipv6=auto
network  --hostname=localhost.localdomain

# System services
services --enabled="chronyd"
# System timezone
timezone Europe/Berlin --isUtc
user --groups=wheel --name=fedora --gecos="Fedora"
#USER_PLACEHOLDER DO NOT DELETE!

# X Window System configuration information
xconfig  --startxonboot
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
autopart --type=lvm
# Partition clearing information
clearpart --none --initlabel

reboot

%packages
@^gnome-desktop-environment
@base
@core
@desktop-debugging
@dial-up
@directory-client
@fonts
@gnome-desktop
@guest-agents
@guest-desktop-agents
@input-methods
@internet-browser
@java-platform
@multimedia
@network-file-system-client
@networkmanager-submodules
@print-client
@x11
chrony
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post --erroronfail

authconfig \
--enablesssd \
--enablesssdauth \
--enablelocauthorize \
--enableldap \
--enableldapauth \
--ldapserver="KERBEROS_SERVER" \
--ldapbasedn="LDAP_SEARCHBASE" \
--disableldaptls \
--enablerfc2307bis \
--enablemkhomedir \
--enablecachecreds \
--update

authconfig --updateall

cat<<EOF >/etc/sssd/sssd.conf
[sssd]
config_file_version = 2
domains   = KERBEROS_DOMAIN
services  = nss,pam,pac

[nss]
filter_users = root,fedora

[pam]
offline_credentials_expiration = 365

[domain/KERBEROS_DOMAIN]
krb5_server   = KERBEROS_SERVER
krb5_realm    = KERBEROS_DOMAIN

id_provider      = proxy
proxy_lib_name   = files

auth_provider     = krb5
cache_credentials = True
EOF

chmod 600 /etc/sssd/sssd.conf

systemctl enable sssd
%end
