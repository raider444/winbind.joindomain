#!/bin/bash

cn=$1
server={{winbind_krb.realms.admin_server}}
basedn=dc=biocad,dc=loc #Put your basedn
port=389
bindUser=evelopers_read
bindPass="Rc42B&"
#cn=mathieu

if [ $cn == "centos" ] || [ $cn == debian ] || [ $cn == ubuntu ]; then
        echo "{{ winbind_ssh_public }}"
exit 0
fi

ldap_response=$(ldapsearch -LLL -o ldif-wrap=no -x -h $server -p $port -b $basedn -D $bindUser -w $bindPass -s sub "(sAMAccountName=$cn)")
uAC=$(echo "$ldap_response" | sed -n 's/^[ \t]*userAccountControl:[ \t]*\(.*\)/\1/p')

i=$((24+2))
while [ $i -gt 0 ]
do
        i=$[ i - 1 ]
        if [ $(( 2 ** $i - $uAC )) -le 0 ]
                then
                        uAC=$(( $uAC - 2 ** $i ))
                        bits[i]=0
                else
                        bits[i]=1
        fi
done

#echo $uAC

if [ ${bits[1]} == 1 ] || [ ${bits[1]} == 4 ] || [ ${bits[1]} == 23 ]; then
        echo "$ldap_response" | sed -n 's/^[ \t]*sshPublicKeys:[ \t]*\(.*\)/\1/p'
else
        echo "Account is locked or disabled"
        logger -p auth.notice -t LDAP-AUTH "Account $cn is locked or disabled"
fi

