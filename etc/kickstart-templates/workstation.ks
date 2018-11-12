#version=DEVEL
ignoredisk --only-use=sda

#autopart --type=plain --fstype=xfs --> runs into troubles with 15GB limit
autopart --type=lvm

# Partition clearing information
clearpart --none --initlabel

# Add repo rpmfusion
repo --name=fedora                 --baseurl=http://ftp.informatik.uni-frankfurt.de/fedora/releases/29/Everything/x86_64/os/
repo --name=updates                --baseurl=http://ftp.informatik.uni-frankfurt.de/fedora/updates/29/Everything/x86_64/
repo --name=rpmfusion-free         --baseurl=http://download1.rpmfusion.org/free/fedora/releases/29/Everything/x86_64/os/
repo --name=rpmfusion-free-updates --baseurl=http://download1.rpmfusion.org/free/fedora/updates/29/x86_64/
repo --name=google-chroome         --baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64/
repo --name=docker-ce              --baseurl=https://download.docker.com/linux/fedora/28/$basearch/stable

# Use graphical install
# graphical
# Use text install
text
# Use CDROM installation media
cdrom
# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate
network  --hostname=localhost.localdomain

#Root password
rootpw --lock
# Run the Setup Agent on first boot
firstboot --enable
# Do not configure the X Window System
skipx
# System services
services --enabled="chronyd"
# System timezone
timezone Europe/Berlin --isUtc
user --groups=wheel --name=fedora --gecos="Fedora"
#USER_PLACEHOLDER DO NOT DELETE!

reboot

%packages
chrony
@anaconda-tools
@base-x
@cinnamon-desktop
@core
@dial-up
@fonts
@guest-desktop-agents
@hardware-support
@input-methods
@libreoffice
@multimedia
@networkmanager-submodules
@printing
@standard

rpmfusion-free-release
krb5-workstation
docker-ce 
kmod-VirtualBox 
virtualbox-guest-additions-ogl
#google-chrome-stable
git
evolution
evolution-ews
ansible
strace
ltrace
docker-compose
subversion
ruby
openldap-clients

# For atom
esmtp
liblockfile
m4
mailx
ncurses-compat-libs
redhat-lsb-core
spax
#libesmtp
#redhat-lsb-submod-security

%end

%addon com_redhat_kdump --disable --reserve-mb='128'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post --erroronfail


# Fix: go for 28 as long as 29 builds are not available
# Deactivate curl for now as Fedora 29 repos are not available
# curl -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/fedora/docker-ce.repo

cat<<EOF >/etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/fedora/28/\$basearch/stable
#baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF


mkdir               /home/fedora/.ssh
chown fedora.fedora /home/fedora/.ssh
chmod 700           /home/fedora/.ssh

touch               /home/fedora/.ssh/authorized_keys
chown fedora.fedora /home/fedora/.ssh/authorized_keys
chmod 600           /home/fedora/.ssh/authorized_keys

cat<<EOF >>/home/fedora/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1VvKTO5DJ27+CzcOHSZiz9OQCXN8G8tNbn2Qsm9X1hU4HgutWEwurb3S0jZmJpQIpo6MoMsPd2cQz1sYxnFEkiZv6lH2k5xbKv6HX84BRGdG4QM5QrScJsYRbQ0KkJszSReuzhqZH00PyrxPketUWGGXo2xfI/c7P0N5W5ME1dDoX86mL5gR9FFBnshFbYx0/lsBt00JXPsiThPveEA1Tpgx20zamXXEucQdYA+Awuj0Od+6nDuNUpois4MTKw+KyNY/wHZ18aahAyLTe+f3k15q+gB4YLt3tlDH+uf459vCHaC1tiR/DjeccdQ2RN59eb/GHHxar+iyhIk3WbYDH fedora
EOF

cat<<EOF >/etc/yum.repos.d/google-chrome-repo
[google-chrome]
name=google-chrome - \$basearch
baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF

dnf update  --nogpgcheck -y
dnf install --nogpgcheck -y docker-ce kmod-VirtualBox google-chrome-stable
systemctl enable docker

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

cat >/etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/cinnamon-session
DISPLAYMANAGER=/usr/sbin/lightdm
EOF

cat<<EOF >/etc/openldap/ldap.conf
#
# LDAP Defaults
#

# See ldap.conf(5) for details
# This file should be world readable but not world writable.

BASE    LDAP_SEARCHBASE
URI	ldap://KERBEROS_SERVER

SIZELIMIT	12
#TIMELIMIT	15
#DEREF		never

# When no CA certificates are specified the Shared System Certificates
# are in use. In order to have these available along with the ones specified
# by TLS_CACERTDIR one has to include them explicitly:
#TLS_CACERT	/etc/pki/tls/cert.pem

# System-wide Crypto Policies provide up to date cipher suite which should
# be used unless one needs a finer grinded selection of ciphers. Hence, the
# PROFILE=SYSTEM value represents the default behavior which is in place
# when no explicit setting is used. (see openssl-ciphers(1) for more info)
#TLS_CIPHER_SUITE PROFILE=SYSTEM

# Turning this off breaks GSSAPI used with krb5 when rdns = false
SASL_NOCANON	on
SASL_MECH       GSSAPI

EOF

authselect select sssd --force with-krb5
systemctl set-default graphical.target

# Unlock acount otherwise it will not show up in the greeter
USER_NAME=USER_PLACEHOLDER
passwd -f -u $USER_NAME
passwd -f -u fedora

cd /home/$USER_NAME/
curl -OL https://github.com/atom/atom/releases/download/v1.32.1/atom.x86_64.rpm
rpm --install atom.x86_64.rpm
chown $USER_NAME.users atom.x86_64.rpm
#rm            atom.x86_64.rpm

CACERT="/etc/pki/ca-trust/source/anchors/devops_self_signed_certificate.crt"
cat<<EOF >"$CACERT"
-----BEGIN CERTIFICATE-----
MIIGDjCCA/agAwIBAgIFLvzgHuowDQYJKoZIhvcNAQELBQAwgZ0xCzAJBgNVBAYT
AkRFMRswGQYDVQQIDBJCYWRlbi1XdWVydHRlbWJlcmcxDDAKBgNVBAcMA1VsbTEq
MCgGA1UECgwhQEBAQF9TRUxGX1NJR05FRF9DRVJUSUZJQ0FURV9AQEBAMTcwNQYD
VQQDDC5AQEBAX1NFTEZfU0lHTl9ST09UX0NFUlRJRklDQVRFX0FVVEhPUklUWV9A
QEBAMB4XDTE4MTEwNDE5MjYwNVoXDTIyMTEwMzE5MjYwNVowgZ0xCzAJBgNVBAYT
AkRFMRswGQYDVQQIDBJCYWRlbi1XdWVydHRlbWJlcmcxDDAKBgNVBAcMA1VsbTEq
MCgGA1UECgwhQEBAQF9TRUxGX1NJR05FRF9DRVJUSUZJQ0FURV9AQEBAMTcwNQYD
VQQDDC5AQEBAX1NFTEZfU0lHTl9ST09UX0NFUlRJRklDQVRFX0FVVEhPUklUWV9A
QEBAMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAz2237qACWm7n23DF
fn9QWsEKLmTil/9iFmMfDFIWdw4RxV/ixTPj4xgzobduFq7xCsJsFuzYo+63HP7P
5TpcbfHX+xVYnOdVGF2KeOUSH3/VyHbk+tqIAMTQTVu4FntvTQaakleKNiuVqFo8
MHdRbSg06sS4OgRDlFH2AQcSu05/uF+C0CAOJ99s+1Ta22GcQRyEtfA6VnIXrxSx
UiYdbsmWtIfsDyel2ro9P+XTkVnVjuGx5gppEmFURl/4OFieYGsvo8Vh0qouiqI0
HbSHdraCku0V0/XAUd3ABpXDM3E9ag3QdcPS+A5V1vVHNO/fFHSC0dqhGgzy7Bwe
QC5lbRaT58hDobWPAWVzohOc9UqHKG3dRwc6nwD/dOToPs41SHp4jGHCgz0GDlxN
iS1gh7k3mmKzEXgXzAv8FcZFJj+D6lB4HM+bTjKKQD2Mp9SlDVb3UhSb9IrNvPh4
XHhmOsW6CDq5CZvKOrFx28LOatLGuhxubWM0TIxLuYX6+VgBZ3fw0+QK3MoVhijj
rn0B9Y/TtUtNO4E3SczPyac9RgPnvumSXtxjxiiH9it4EFxSdD5tMK8feDv1mDjq
02myz2K205FXdRDyCigoI6ESE80ohUhbL1NWtCdV9w5z/aemhsshJ/Lwp28SasWK
ESXqvxfmZ8kIznQ1XvncQD8a490CAwEAAaNTMFEwHQYDVR0OBBYEFMxVFvJRWh1I
CeYsD5eNpKY2roTIMB8GA1UdIwQYMBaAFMxVFvJRWh1ICeYsD5eNpKY2roTIMA8G
A1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggIBACrhBfPkjWPU7TQG344P
qW8P32R0WqMhACMRbbtyviTGJS+6x5fSMdWJkSb8WMPTJzBYxXFo1J6gK4JmLmYi
EWCAbxUZmY7Q7GTWZ2QSac1CHK4b9fg4oqSouXNepXuuMKU/Z3P09yVoBUbXuGVA
r+uvBCM9KwkVfBebKEPu7mFn/xeP67Dy3dhCGNGJuS2f3wrKSdS+xXWsibUinqTL
YaI76ubsjTMSYeO4m79OYwacwDAE5v6FNGlIyd2ydpqjBhzAlE3SHAOzKL41MiAq
EiTZNgPXZecJOI9JSkkFuKwdSTIM7ARdFmqaEY4Hz4JqkoM9GuTjEXDFSEb4gIxl
YkAldPIwnA1yL9Bm7OrFxaGV3H5f/LiHJvPbSF66ioGiJ3fFZTtOyT3M6F2VgsHV
nZCp/lEJ1CjI9VsuInqtbAD9Qpyl+CyeJlWn9AHU6+MV6QXIBBPxHk/Fx5xni7dE
gD7tcF/KJ+ezT+uUzPy1L6M1nEATDJEJQUJIxvvBZk6/ouQdHvdxwh6CwUca2s0o
n2kyzomTQAnqjUwMfw2dRMpDIG5dFJpJ1n0t8o53B1wmdiIadF/od9tqaUJAF1cs
N8ngj1hw7gThlye2IlLPHH79FHOv+TcplPKeBRc02dkbbqXyBsOK7XQ/gf8xasqI
fVlGCcggD4OsczDjOzm35HTk
-----END CERTIFICATE-----
EOF

chmod 600 $CACERT
update-ca-trust enable
update-ca-trust extract

# Resize root partition to maximum size (as Fedora Server defaults it to 15GB)
LVPATH=$(lvdisplay |grep -E "LV Path.*/root$" |awk 'END{print $NF}')

if [ -n "$LVPATH" ]; then
  lvextend -l +100%FREE "$LVPATH"
  df -hT  >df.txt
  xfs_growfs /
fi

# After all these changes restore security contexts 
restorecon -R /

%end
