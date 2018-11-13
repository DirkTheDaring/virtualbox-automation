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
krb5_server       = KERBEROS_SERVER
krb5_realm        = KERBEROS_DOMAIN

id_provider       = proxy
proxy_lib_name    = files
auth_provider     = krb5
cache_credentials = True
EOF

chmod 600 /etc/sssd/sssd.conf
systemctl enable sssd


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



cat<<EOF >/etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/7/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

yum update  --nogpgcheck -y
yum install --nogpgcheck -y docker-ce
systemctl enable docker

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

%end
