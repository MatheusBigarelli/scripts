#!/bin/bash

# Comandos necessarios pelo programa


# Diretorios usados ao longo do programa
dir_ldapscripts=/usr/local/etc/ldapscripts


# Checa se e usuario root
if [ `/usr/bin/id -u` != 0 ]; then
	echo "Necessario usuario root"
	exit
fi

cd /root/

# Atualiza SO
apt update
apt upgrade -y

# Instala programas necessarios para o ldap
apt install ldap-utils slapd -y
dpkg-reconfigure slapd
#libpam-ldap

# Instala nfs
apt install nfs-common

# Instala make
# Necessario para instalar o ldapscripts
apt install make

mkdir /home/users

echo "192.168.0.253:/home/users /home/users nfs defaults 0 0" >> /etc/fstab



# Pega arquivo necessario no github
wget https://raw.githubusercontent.com/arthurdejong/nss-pam-ldapd/master/ldapns.ldif

# Pega arquivo de scripts necessario ao ldap
wget http://contribs.martymac.org/ldapscripts/ldapscripts-2.0.8.tgz

gunzip ldapscripts-2.0.8.tgz
tar xf ldapscripts-2.0.8.tar

cd ldapscripts-2.0.8/
make install
cd ..

# Cria arquivo ldapOU.ldif com o conteudo entre as tags END
cat > /etc/ldap/ldapOU.ldif <<- END
#Groups
dn: ou=Groups,dc=bioinfo-ic,dc=ct,dc=utfpr,dc=edu,dc=br
objectClass: organizationalUnit
ou: Groups

# Users
dn: ou=Users,dc=bioinfo-ic,dc=ct,dc=utfpr,dc=edu,dc=br
objectClass: organizationalUnit
ou: Users

# Machines
dn: ou=Machines,dc=bioinfo-ic,dc=ct,dc=utfpr,dc=edu,dc=br
objectClass: organizationalUnit
ou: Machines
END

ldapadd -f /etc/ldap/ldapOU.ldif -D cn=admin,dc=bioinfo-ic,dc=ct,dc=utfpr,dc=edu,dc=br -W
ldapadd -Y EXTERNAL -H ldapi:/// -f ldapns.ldif

# Adiciona os grupos na configuracao do ldap
for i in "admin alunos projetos tmp"; do
	/usr/local/sbin/ldapaddgroup $i
done


# Algumas mudancas no arquivo de configuracao ldapscripts.conf
server='SERVER="ldap://192.168.0.253"'
binddn='BINDDN="cn=admin,dc=bioinfo-ic,dc=ct,dc=utfpr,dc=edu,dc=br"'
bindpwdfile='BINDPWDFILE="/usr/local/etc/ldapscripts/ldapscripts.passwd"'
suffix='SUFFIX="dc=bioinfo-ic,dc=ct,dc=utfpr,dc=edu,dc=br"'
gsuffix='GSUFFIX="ou=Groups"'
usuffix='USUFFIX="ou=Users"'
msuffix='MSUFFIX="ou=Machines"'
ushell='USHELL="/bin/bash"'
uhomes='UHOMES="/home/users/%u"'
createhomes='CREATEHOMES="yes"'
homeskel='HOMESKEL="/etc/skel"'
homeperms='HOMEPERMS="700"'
passwordgen='PASSWORDGEN="echo @@%u!!"'
gidstart='GIDSTART="10000"'
uidstart='UIDSTART="10000"'
midstart='MIDSTART="20000"'
iconvchar='ICONVCHAR="ISO-8859-15"'
iconvbin='#ICONVBIN="/usr/bin/iconv"'

# Insercao das mudancas no arquivo
# O comando sed substitui partes de um arquivo
# -i quer dizer inline
sed -i "s#^SERVER.*#${server}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^BINDDN.*#${binddn}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^BINDPWDFILE.*#${bindpwdfile}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^SUFFIX.*#${suffix}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^GSUFFIX.*#${gsuffix}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^USUFFIX.*#${usuffix}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^MSUFFIX.*#${msuffix}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^USHELL.*#${ushell}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^UHOMES.*#${uhomes}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^CREATEHOMES.*#${createhomes}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^HOMESKEL.*#${homeskel}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^HOMEPERMS.*#${homeperms}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^PASSWORDGEN.*#${passwordgen}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^GIDSTART.*#${gidstart}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^UIDSTART.*#${uidstart}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s#^MIDSTART.*#${midstart}#" $dir_ldapscripts/ldapscripts.conf
sed -i "s!^#ICONVCHAR.*!${iconvchar}!" $dir_ldapscripts/ldapscripts.conf
sed -i "s!^ICONVBIN.*!${iconvbin}!" $dir_ldapscripts/ldapscripts.conf
