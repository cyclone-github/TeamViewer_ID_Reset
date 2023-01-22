#!/bin/bash

# script by cyclone to reset teamviewer id on linux
# script must by run as sudo
# scrip will temporarily change mac address & hostname, but will return both
# to their previous value after option 3 has completed & pc has been rebooted
# v0.2.0
# build 2023-01-21.1730

clear

# check if script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   echo "ex: sudo ./cyclone_teamviewer_id_reset.sh"
   exit 1
fi

echo "Please select an option:"
echo "1. Run 1st (preps & reboots pc)"
echo "2. Run 2nd (reinstalls teamviewer)"
echo ""
read option

if [ "$option" == "1" ]; then
    echo "Running 1st option."
    echo "Removing teamviewer 1/4"
    # check if teamviewer is installed
    if command -v teamviewer >/dev/null; then
        # save teamviewer ID
        teamviewer info | grep -i 'TeamViewer ID' | egrep -o '[0-9]{3,}' > teamviewer_id.txt &>/dev/null
        # return to default settings
        teamviewer repo default &>/dev/null
        # stop teamviewer
        systemctl stop teamviewerd &>/dev/null
        # remove teamviewer
        apt autoremove --purge teamviewer teamviewer-host -y &>/dev/null
    fi
    # remove teamviewer directories
    rm -fr ~/.teamviewer* &>/dev/null
    rm -fr /opt/teamviewer* &>/dev/null
    rm -fr /var/log/teamviewer* &>/dev/null

    # change /etc/hostname
    # Get the current hostname
    echo 'Temperarily changing hostname 2/4'
    current_hostname=$(cat /etc/hostname) &>/dev/null
    echo $current_hostname > original_hostname.txt
    # Generate a random 4 char string
    random_string=$(head -n 100 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1) &>/dev/null
    # Append the random string to the current hostname
    new_hostname="$current_hostname-$random_string" &>/dev/null
    # Update the /etc/hostname file
    cat $new_hostname > /etc/hostname &>/dev/null
    hostnamectl set-hostname $new_hostname &>/dev/null
    # Update the running hostname
    hostname $new_hostname &>/dev/null

    # remove machine id
    echo 'Changing machine ID 3/4'
    fileID="/var/lib/dbus/machine-id"
    if [ -f $fileID ]; then
        cat $fileID > machine_id_old.txt
        rm -f $fileID
    fi
    echo 'Temperarily changing mac address 4/4'
    # Generate a random 32 character string of hexadecimal digits (a-f and 0-9)
    rand_string=$(head -n 100 /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1) &>/dev/null
    # Replace the contents of /var/lib/dbus/machine-id with the random string
    echo $rand_string > $fileID

    # Get the current MAC address of the connected LAN network card
    mac_address=$(ip link show $(ip route | grep default | awk '{print $5}') | grep ether | awk '{print $2}') &>/dev/null

    # Generate a random 4 character string of hexadecimal digits (a-f and 0-9)
    rand_string=$(head -n 100 /dev/urandom | tr -dc 'a-f0-9' | fold -w 4 | sed 's/^\(.\{2\}\)/\1:/' | head -n 1) &>/dev/null

    # Replace the last 4 characters of the MAC address with the random string
    new_mac_address="${mac_address::-5}$rand_string"

    # Set the new MAC address on the network card
    ip link set dev $(ip route | grep default | awk '{print $5}') address $new_mac_address &>/dev/null

    systemctl restart networking &>/dev/null

    # reboot system
    echo 'Press any key to reboot pc...'
    read
    shutdown -r now

elif [ "$option" == "2" ]; then
    echo "Running 2nd option."
    echo "Resetting ID 1/6"
    
    # change /etc/hostname
    # Get the current hostname
    current_hostname=$(cat /etc/hostname) &>/dev/null
    # Generate a random 4 char string
    random_string=$(head -n 100 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1) &>/dev/null
    # Append the random string to the current hostname
    new_hostname="$current_hostname-$random_string" &>/dev/null
    # Update the /etc/hostname file
    cat $new_hostname > /etc/hostname &>/dev/null
    hostnamectl set-hostname $new_hostname &>/dev/null
    # Update the running hostname
    hostname $new_hostname &>/dev/null

    # remove machine id
    fileID="/var/lib/dbus/machine-id"
    if [ -f $fileID ]; then
        cat $fileID > machine_id_old.txt
        rm -f $fileID
    fi
    # Generate a random 32 character string of hexadecimal digits (a-f and 0-9)
    rand_string=$(head -n 100 /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1) &>/dev/null
    # Replace the contents of /var/lib/dbus/machine-id with the random string
    echo $rand_string > $fileID &>/dev/null

    # Get the current MAC address of the connected LAN network card
    mac_address=$(ip link show $(ip route | grep default | awk '{print $5}') | grep ether | awk '{print $2}')  &>/dev/null

    # Generate a random 4 character string of hexadecimal digits (a-f and 0-9)
    rand_string=$(head -n 100 /dev/urandom | tr -dc 'a-f0-9' | fold -w 4 | sed 's/^\(.\{2\}\)/\1:/' | head -n 1) &>/dev/null

    # Replace the last 4 characters of the MAC address with the random string
    new_mac_address="${mac_address::-5}$rand_string" &>/dev/null

    # Set the new MAC address on the network card
    ip link set dev $(ip route | grep default | awk '{print $5}') address $new_mac_address &>/dev/null

    systemctl restart networking &>/dev/null
    sleep 1

    echo "Reinstalling teamviewer 2/6"
    echo "This may take a few minutes to complete."
    # apt install wget, gdebi
    if ! command -v wget >/dev/null; then
        # Run action
        echo 'Installing wget'
        apt update &>/dev/null
        apt install wget -y &>/dev/null
    fi

    if ! command -v gdebi >/dev/null; then
        # Run action
        echo 'Installing gdebi'
        apt update &>/dev/null
        apt install gdebi -y &>/dev/null
    fi

    # download teamviewer
    #file="teamviewer_amd64.deb" # teamviewer
    file="teamviewer-host_amd64.deb" # teamviewer host
    file13Old="teamviewer_13old.deb"
    file14Old="teamviewer_14old.deb"
    url="https://download.teamviewer.com/download/linux"
    url13Old="https://download.teamviewer.com/download/linux/version_13x"
    url14Old="https://download.teamviewer.com/download/linux/version_14x"
    
    # remove existing teamviewer binaries
    if [ -f $file ]; then
        mv $file $file.bak &>/dev/null
    fi

    if [ -f $file13Old ]; then
        mv $file13Old $file13Old.bak &>/dev/null
    fi

    if [ -f $file14Old ]; then
        mv $file14Old $file14Old.bak &>/dev/null
    fi

    # download teamviewer binaries
    if [ ! -f $file ]; then
        echo 'Downloading file 1/3'
        wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36" -O $file $url/$file &>/dev/null && echo 'Ok' || echo 'Failed'
    fi

    if [ ! -f $file13Old ]; then
    echo 'Downloading file 2/3'
        wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36" -O $file13Old $url13Old/$file &>/dev/null && echo 'Ok' || echo 'Failed'
    fi

    if [ ! -f $file14Old ]; then
    echo 'Downloading file 3/3'
        wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36" -O $file14Old $url14Old/$file &>/dev/null && echo 'Ok' || echo 'Failed'
    fi

    # install teamviewer
    if ! command -v teamviewer >/dev/null; then
        # generate random password
        random_passwd=$(head -n 100 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1) &>/dev/null
        # install teamviewer v13
        gdebi -n $file13Old &>/dev/null && echo "Step 3/6 Complete" || echo "Step 3/6 Failed"
        #teamviewer setup # only needed if installing on CLI 
        teamviewer repo default &>/dev/null
        sleep 1
        systemctl restart teamviewerd &>/dev/null
        sleep 1
        # set password
        teamviewer passwd $random_passwd &>/dev/null
        sleep 10

        # install teamviewer v14
        systemctl stop teamviewerd &>/dev/null
        apt remove teamviewer teamviewer-host -y &>/dev/null
        gdebi -n $file14Old &>/dev/null && echo "Step 4/6 Complete" || echo "Step 4/6 Failed"
        #teamviewer setup # only needed if installing on CLI
        teamviewer repo default &>/dev/null
        sleep 1
        systemctl restart teamviewerd &>/dev/null
        sleep 1
        # set password
        teamviewer passwd $random_passwd &>/dev/null

        # install latest teamviewer version
        systemctl stop teamviewerd &>/dev/null
        apt remove teamviewer teamviewer-host -y &>/dev/null
        gdebi -n $file &>/dev/null && echo "Step 5/6 Complete" || echo "Step 5/6 Failed"
        #teamviewer setup # only needed if installing on CLI
        teamviewer repo default &>/dev/null
        sleep 1
        systemctl restart teamviewerd &>/dev/null
        # set password
        teamviewer passwd $random_passwd &>/dev/null
        # show teamviewer ID
        sleep 10
        echo 'Previous TeamViewer ID:'
        cat teamviewer_id.txt | egrep -o '[0-9]{3,}'
        echo 'Current TeamViewer ID:'
        teamviewer info | grep -i 'TeamViewer ID' | egrep -o '[0-9]{3,}'
        echo 'Teamviewer Password:'
        echo $random_passwd | tee teamviewer_passwd.txt

        # restore original hostname
        echo 'Restoring original hostname 6/6'
        new_hostname=$(cat original_hostname.txt) &>/dev/null
        # Update the /etc/hostname file
        echo $new_hostname > /etc/hostname &>/dev/null
        hostnamectl set-hostname $new_hostname &>/dev/null
        # Update the running hostname
        hostname $new_hostname &>/dev/null

        # reboot system
        echo 'Press any key to reboot pc...'
        # delete tmp files
        rm -f $file, $file.bak, $file13Old, $file13Old.bak, $file14Old, $file14Old, $file14Old.bak, machine_id_old.txt, teamviewer_id.txt &>/dev/null
        read
        shutdown -r now
    else
        echo "Resetting Teamviewer ID failed..."
        exit 1
    fi

else
    echo "Invalid option selected. Exiting."
    exit 1
fi

# end of script
