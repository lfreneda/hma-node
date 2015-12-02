# Function to check external IP
function checkip()
{
	ip=""
	attempt=0
	while [ "$ip" = "" ]; do
	        attempt=$(($attempt+1))
	        ip=`curl http://geoip.hmageo.com/ip/ 2>/dev/null`
	        if [ "$ip" != "" ]; then
	            if [ ! "$1" == "silent" ] ; then echo " > Real current IP: $ip" ; fi
	        fi
	        if [ $attempt -gt 3 ]; then
	            if [ ! "$1" == "silent" ] ; then echo " > Failed to check current IP address." ; fi
	                exit
	        fi
	done
}

# Check what package managers are available, yum or apt-get. If both, use apt-get
pkgmgr=""
if [[ ! $(which yum) == "" ]] ; then
	pkgmgr="yum install"
fi
if [[ ! $(which apt-get) == "" ]] ; then
	pkgmgr="apt-get install"
fi

# Function to check for and install needed packages
function checkpkg
{
	if [[ $(which $1) == "" ]] ; then
		echo -n "Package '$1' not found! Attempt installation? (y/n) "
		read -n1 answer
		echo
		case $answer in
			y) $pkgmgr $1
			;;
			n) echo -n "Proceed anyway? (y/n) "
			read -n1 answer2
			echo
			if [[ "$answer2" == "n" ]] ; then exit
			fi
			;;
		esac
	fi
}

# If no su privileges available, try to get them
if [[ ! "$(whoami)" == "root" ]] ; then

	# No sudo available? Then we can't get su privs. Advise and exit
	if [[ $(which sudo) == "" ]] ; then
		echo "'sudo' package missing! Please install."
		echo "e.g.: apt-get install sudo"
		exit 1
	fi

	echo "Requesting su permissions..."
	# Run this script with sudo privs
	sudo $0 $*
		# If running this script with su privs failed, advise to do so manually and exit
		if [[ $? > 0 ]] ; then
		echo
		echo "Acquiring su permission failed!"
		echo "Please run this script with sudo permissions!"
		echo "(e.g. 'sudo $0' or 'sudo bash $0')"
		echo
		exit 1
	fi
exit 0
fi

# Check for all needed packages
checkpkg curl
checkpkg openvpn

killall openvpn 2>/dev/null
sleep 5

checkip
sleep 2

openvpn --daemon --script-security 3 --config random-openvpn-template.ovpn
echo " > Waiting for connection process to complete.."
sleep 5

oldip=$ip
ipattempt=0
while [ "$ipattempt" -lt "10" ]; do
	ipattempt=$(($ipattempt+1))
	echo " > Waiting for connection process to complete.."
	checkip silent
	if [ ! "$ip" == "$oldip" ] ; then
		echo " > Connection successful, IP has changed ($oldip -> $ip)"
		ipattempt=10
	fi
	sleep 5
done

if [ "$ip" == "$oldip" ] ; then
    echo " - IP has not changed! Please check for possible network problems."
    killall openvpn 2>/dev/null
	echo " > Exiting script..."
	exit 1
fi

echo " > Exiting script..."
exit 0
