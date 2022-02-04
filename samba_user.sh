#!/bin/bash 

function log {
echo "$1" | tee -a /home/ubuntu/decoy.log
}

function xml_parsing {
parsed=false
file=decoy.xml
if test -f "$file"; then
	name=$(xmlstarlet sel --template --value-of 'Decoys/Name' --nl decoy.xml)
    domain=$(xmlstarlet sel --template --value-of 'Decoys/Domain' --nl decoy.xml)
    hostname=$(xmlstarlet sel --template --value-of 'Decoys/HostName' --nl decoy.xml)
    site=$(xmlstarlet sel --template --value-of 'Decoys/Site' --nl decoy.xml)

    user1=$(xmlstarlet sel --template --value-of 'Decoys/User/User1' --nl decoy.xml)
    last1=$(xmlstarlet sel --template --value-of 'Decoys/User/Last1' --nl decoy.xml)
    pass1=$(xmlstarlet sel --template --value-of 'Decoys/User/Pass1' --nl decoy.xml)
    user2=$(xmlstarlet sel --template --value-of 'Decoys/User/User2' --nl decoy.xml)
    last2=$(xmlstarlet sel --template --value-of 'Decoys/User/Last2' --nl decoy.xml)
    pass2=$(xmlstarlet sel --template --value-of 'Decoys/User/Pass2' --nl decoy.xml)
    user3=$(xmlstarlet sel --template --value-of 'Decoys/User/User3' --nl decoy.xml)
    last3=$(xmlstarlet sel --template --value-of 'Decoys/User/Last3' --nl decoy.xml)
    pass3=$(xmlstarlet sel --template --value-of 'Decoys/User/Pass3' --nl decoy.xml)

    comp1=$(xmlstarlet sel --template --value-of 'Decoys/Computer/Computer1' --nl decoy.xml)
    os1=$(xmlstarlet sel --template --value-of 'Decoys/Computer/os1' --nl decoy.xml)
    comp2=$(xmlstarlet sel --template --value-of 'Decoys/Computer/Computer2' --nl decoy.xml)
    os2=$(xmlstarlet sel --template --value-of 'Decoys/Computer/os2' --nl decoy.xml)
    comp3=$(xmlstarlet sel --template --value-of 'Decoys/Computer/Computer3' --nl decoy.xml)
    os3=$(xmlstarlet sel --template --value-of 'Decoys/Computer/os3' --nl decoy.xml)
    
    group1=$(xmlstarlet sel --template --value-of 'Decoys/Group/Group1' --nl decoy.xml)
    group_pass1=$(xmlstarlet sel --template --value-of 'Decoys/Group/Pass1' --nl decoy.xml)

	username1=$user1"_"$last1
	username2=$user2"_"$last2
	username3=$user3"_"$last3

    # echo $name $domain $hostname $site $user1 $last1 $pass1 
    # echo $user2 $last2 $pass2
    # echo $user3 $last3 $pass3
    # echo $comp1 $os1
    # echo $comp2 $os2
    # echo $comp3 $os3
    #echo $group1 $group_pass1
	#echo $parsed

	parsed=true
	log "XML parsing completed successfully."
else
	log "XML file is not exist."
	exit 0
fi
}

function samba {
echo $ip
/usr/local/samba/bin/samba-tool dns zonecreate $hostname 0.99.10.in-addr.arpa -U Administrator --password Admin@123
cp /usr/local/samba/private/krb5.conf /etc/krb5.conf
if [ $? -eq 0 ]; then
	log "Kerberos configuration successfull."
	/usr/local/samba/bin/samba-tool user create $username1 $pass1 --given-name=$user1 --surname=$last1 --mail-address=$user1.$last1@$domain --login-shell=/bin/bash
	/usr/local/samba/bin/samba-tool user create $username2 $pass2 --given-name=$user2 --surname=$last2 --mail-address=$user2.$last2@$domain --login-shell=/bin/bash
	/usr/local/samba/bin/samba-tool user create $username3 $pass3 --given-name=$user3 --surname=$last3 --mail-address=$user3.$last3@$domain --login-shell=/bin/bash
	if [ $? -eq 0 ]; then
		log "User created successfully."
		/usr/local/samba/bin/samba-tool group add $group1
		if [ $? -eq 0 ]; then
			log "Group Added successfully."
			/usr/local/samba/bin/samba-tool group addmembers $group1 $username1
			/usr/local/samba/bin/samba-tool group addmembers $group1 $username2
			/usr/local/samba/bin/samba-tool group addmembers $group1 $username3
			if [ $? -eq 0 ]; then
				log "Users added to groups."
			else
				log "Error while adding to adding users to group."
				exit $?
			fi
		else
			log "Error while adding group."
			exit $?
		fi
	else
		log "Error while creating user."
		exit $?
	fi
else
	log "Error while Kerberos configuration."
	exit $?
}

xml_parsing
samba