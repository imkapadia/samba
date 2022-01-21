#!/bin/bash 

function os_detection {
#OS Version Ubuntu 20
if [ "$(cat /etc/*-release | grep focal)" ]; then
	dist=ubuntu
	osv=focal
	version=20
	result="$dist $version OS detected"
#OS Version Ubuntu 18
elif [ "$(cat /etc/*-release | grep bionic)" ]; then
	dist=ubuntu
	osv=bionic
	version=18
	result="$dist $version OS detected"
#OS Version Centos 8
elif [ "$(cat /etc/*-release | grep 'CentOS Linux release 8')" ] || [ "$(cat /etc/*-release | grep 'CloudLinux release 8')" ]; then
	dist=centos
	osv=8
	version=8
	result="$dist $version OS detected"
#OS Version Centos 7
elif [ "$(cat /etc/*-release | grep 'CentOS Linux release 7')" ] || [ "$(cat /etc/*-release | grep 'CloudLinux release 7')" ]; then
	dist=centos
	osv=7
	version=7
	result="$dist $version OS detected"
else
	result="Can't detect the OS"
	log "$result"
	exit 0
fi
log "$result"
}

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
if [ dist=="ubuntu" ]; then
	tarfile=samba-4.13.16.tar.gz
	if test -f $tarfile; then
		tar -zxf $tarfile
		if [ $? -eq 0 ]; then
			log ".tar file extracted successfully."
			chmod -R a+rwx samba-4.13.16/
			if [ $? -eq 0 ]; then
				log "Permission of samba directory changed successfully."
				cd samba-4.13.16/
				if [ $? -eq 0 ]; then
					log "Moved into samba directory."
					./configure
					if [ $? -eq 0 ]; then
						log "Configuration successfull."
						make
						if [ $? -eq 0 ]; then
							log "make building successfull."
							make install
							if [ $? -eq 0 ]; then
								log "make installing successfull."
								echo "export PATH=$PATH:/usr/local/samba/bin/:/usr/local/samba/sbin/:" | tee -a ~/.bashrc 
								source ~/.bashrc
								systemctl mask smbd nmbd winbind
								systemctl disable smbd nmbd winbind
								if [ $? -eq 0 ]; then
									log "Services masked."
									source ~/.bashrc
									echo "[Unit]
									Description=Samba Active Directory Domain Controller
									After=network.target remote-fs.target nss-lookup.target
									[Service]
									Type=forking
									ExecStart=/usr/local/samba/sbin/samba -D
									PIDFile=/usr/local/samba/var/run/samba.pid
									ExecReload=/bin/kill -HUP $MAINPID

									[Install]
									WantedBy=multi-user.target" > /etc/systemd/system/samba-ad-dc.service
									systemctl daemon-reload
									if [ $? -eq 0 ]; then
										log "Samba-ad-dc service file created successfully."
										source ~/.bashrc
										systemctl enable samba-ad-dc
										if [ $? -eq 0 ]; then
											log "Samba-ad-dc service enabled."
											systemctl start samba-ad-dc
											if [ $? -eq 0 ]; then
												log "Samba-ad-dc service started."
												ip=$(hostname -I)
												if [ $? -eq 0 ]; then
													log "IP fetched successfully."
													dns=$hostname.$domain
													echo $ip $dns $hostname | tee -a /etc/hosts
													if [ $? -eq 0 ]; then
														log "Adding hostname."
														source ~/.bashrc
														/usr/local/samba/bin/samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=SAMBA_INTERNAL --realm=$dns --domain=$hostname --adminpass=Admin@123
														if [ $? -eq 0 ]; then
															log "Samba AD provision successfull."
															echo "search" $dns | tee -a /etc/resolv.conf; echo "nameserver" $ip | tee -a /etc/resolv.conf
															if [ $? -eq 0 ]; then
																log "DNS Resolver configuration successfull."
																systemctl disable samba-ad-dc
																systemctl stop samba-ad-dc
																systemctl enable samba-ad-dc
																systemctl start samba-ad-dc
																if [ $? -eq 0 ]; then
																	log "Samba services restarted."
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
																	fi
																else
																	log "Error while restarting samba services."
																	exit $?
																fi
															else
																log "Error while DNS resolver configuration."
																exit $?
															fi
														else
															log "Error while provisioning Samba AD."
															exit $?
														fi
													else
														log "Error while adding hostname."
														exit $?
													fi								
												else
													log "Error while getting IP."
													exit $?
												fi
											else
												log "Can not enable samba-ad-dc services"
												exit $?
											fi
										else
											log "Can not enable samba-ad-dc services"
											exit $?
										fi
									else
										log "Error while creating Samba-ad-dc service file."
										exit $?
									fi
								else
									log "Error while masking services."
									exit $?
								fi 

							else
								log "Error while Make install."
								exit $?
							fi
						else
							log "Error while Make building."				
							exit $?
						fi						
					else
						log "Error while Configuration."
						exit $?
					fi	
				else
					log "Error while moving into samba directory."
					exit $?
				fi
			else
				log "Error while changing permission of samba directory."
				exit $?
			fi
		else
			log "Error while file extracting .tar file."
			exit $?	
		fi
	else
		log ".tar file is not exist."
		exit 0	
	fi

elif [ dist=="centos" ]; then
	tarfile=samba-4.13.16.tar.gz
	if test -f $tarfile; then
		tar -zxf $tarfile
		if [ $? -eq 0 ]; then
			log ".tar file extracted successfully."
			chmod -R a+rwx samba-4.13.16/
			if [ $? -eq 0 ]; then
				log "Permission of samba directory changed successfully."
				cd samba-4.13.16/
				if [ $? -eq 0 ]; then
					log "Moved into samba directory."
					./configure
					if [ $? -eq 0 ]; then
						log "Configuration successfull."
						make
						if [ $? -eq 0 ]; then
							log "make building successfull."
							make install
							if [ $? -eq 0 ]; then
								log "make installing successfull."
								echo "export PATH=$PATH:/usr/local/samba/bin/:/usr/local/samba/sbin/:" | tee -a ~/.bashrc 
								source ~/.bashrc
								systemctl mask smbd nmbd winbind
								systemctl disable smbd nmbd winbind
								if [ $? -eq 0 ]; then
									log "Services masked."
									source ~/.bashrc
									echo "[Unit]
									Description=Samba Active Directory Domain Controller
									After=network.target remote-fs.target nss-lookup.target
									[Service]
									Type=forking
									ExecStart=/usr/local/samba/sbin/samba -D
									PIDFile=/usr/local/samba/var/run/samba.pid
									ExecReload=/bin/kill -HUP $MAINPID

									[Install]
									WantedBy=multi-user.target" > /etc/systemd/system/samba-ad-dc.service
									systemctl daemon-reload
									if [ $? -eq 0 ]; then
										log "Samba-ad-dc service file created successfully."
										source ~/.bashrc
										systemctl enable samba-ad-dc
										if [ $? -eq 0 ]; then
											log "Samba-ad-dc service enabled."
											systemctl start samba-ad-dc
											if [ $? -eq 0 ]; then
												log "Samba-ad-dc service started."
												ip=$(hostname -I)
												if [ $? -eq 0 ]; then
													log "IP fetched successfully."
													dns=$hostname.$domain
													echo $ip $dns $hostname | tee -a /etc/hosts
													if [ $? -eq 0 ]; then
														log "Adding hostname."
														source ~/.bashrc
														/usr/local/samba/bin/samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=SAMBA_INTERNAL --realm=$dns --domain=$hostname --adminpass=Admin@123
														if [ $? -eq 0 ]; then
															log "Samba AD provision successfull."
															echo "search" $dns | tee -a /etc/resolv.conf; echo "nameserver" $ip | tee -a /etc/resolv.conf
															if [ $? -eq 0 ]; then
																log "DNS Resolver configuration successfull."
																systemctl disable samba-ad-dc
																systemctl stop samba-ad-dc
																systemctl enable samba-ad-dc
																systemctl start samba-ad-dc
																if [ $? -eq 0 ]; then
																	log "Samba services restarted."
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
																	fi
																else
																	log "Error while restarting samba services."
																	exit $?
																fi
															else
																log "Error while DNS resolver configuration."
																exit $?
															fi
														else
															log "Error while provisioning Samba AD."
															exit $?
														fi
													else
														log "Error while adding hostname."
														exit $?
													fi								
												else
													log "Error while getting IP."
													exit $?
												fi
											else
												log "Can not enable samba-ad-dc services"
												exit $?
											fi
										else
											log "Can not enable samba-ad-dc services"
											exit $?
										fi
									else
										log "Error while creating Samba-ad-dc service file."
										exit $?
									fi
								else
									log "Error while masking services."
									exit $?
								fi 

							else
								log "Error while Make install."
								exit $?
							fi
						else
							log "Error while Make building."				
							exit $?
						fi						
					else
						log "Error while Configuration."
						exit $?
					fi	
				else
					log "Error while moving into samba directory."
					exit $?
				fi
			else
				log "Error while changing permission of samba directory."
				exit $?
			fi
		else
			log "Error while file extracting .tar file."
			exit $?	
		fi
	else
		log ".tar file is not exist."
		exit 0
	fi	
fi
}	

os_detection
xml_parsing
samba