#!/bin/bash

if [ `id -u` != 0 ]; then
	echo 'Necessaria permissao de root (sudo)'
	exit
fi

interface_name=$(ip address show to 192.168.100.0/24 | tr ':' '\n' | sed -n 2p)

cd /etc/netplan/

mv * ..

cat > 00-private-nameservers.yaml <<END
network:
    version: 2
    ethernets:
        $interface_name:                                 # Private network interface
            dhcp4: true
            gateway4: 192.168.100.254
            nameservers:
                addresses:
                - 192.168.100.254                # Private IP for ns1
                search: [ labic.example.com ]  # DNS zone
END

netplan try
