#!/bin/bash 

function log {
touch AD_decoy.log
echo "$1" | tee -a AD_decoy.log
}

function config_parsing {
parsed=false
file=ad_config.ini
if test -f "$file"; then
	name=$(awk -F "=" '/username/ {print $2}' ad_config.ini)
    domain=$(awk -F "=" '/domain/ {print $2}' ad_config.ini)
    hostname=$(awk -F "=" '/hostname/ {print $2}' ad_config.ini)
    site=$(awk -F "=" '/site/ {print $2}' ad_config.ini)

    user1=$(awk -F "=" '/user1/ {print $2}' ad_config.ini)
    last1=$(awk -F "=" '/last1/ {print $2}' ad_config.ini)
    pass1=$(awk -F "=" '/password/ {print $2}' ad_config.ini)
    user2=$(awk -F "=" '/user2/ {print $2}' ad_config.ini)
    last2=$(awk -F "=" '/last2/ {print $2}' ad_config.ini)
    pass2=$(awk -F "=" '/password/ {print $2}' ad_config.ini)
    user3=$(awk -F "=" '/user3/ {print $2}' ad_config.ini)
    last3=$(awk -F "=" '/last3/ {print $2}' ad_config.ini)
    pass3=$(awk -F "=" '/password/ {print $2}' ad_config.ini)

    comp1=$(awk -F "=" '/computer1/ {print $2}' ad_config.ini)
    os1=$(awk -F "=" '/os1/ {print $2}' ad_config.ini)
    comp2=$(awk -F "=" '/computer2/ {print $2}' ad_config.ini)
    os2=$(awk -F "=" '/os2/ {print $2}' ad_config.ini)
    comp3=$(awk -F "=" '/computer3/ {print $2}' ad_config.ini)
    os3=$(awk -F "=" '/os3/ {print $2}' ad_config.ini)
    
    group1=$(awk -F "=" '/group1/ {print $2}' ad_config.ini)
    group_pass1=$(awk -F "=" '/password/ {print $2}' ad_config.ini)

	username1=$user1"_"$last1
	username2=$user2"_"$last2
	username3=$user3"_"$last3

    echo $name $domain $hostname $site $user1 $last1 $pass1 
    echo $user2 $last2 $pass2
    echo $user3 $last3 $pass3
    echo $comp1 $os1
    echo $comp2 $os2
    echo $comp3 $os3
    echo $group1 $group_pass1
	echo $parsed

	parsed=true
	log "config parsing completed successfully."
else
	log "config file does not exist."
	exit 0
fi
}

function samba {
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

}

config_parsing
samba