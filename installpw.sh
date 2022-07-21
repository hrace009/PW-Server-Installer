#!/usr/bin/env bash
# Program: Installation for Perfect World Private Server
# History:
# 29-04-2020 hrace009 First created.

clear
PW_VERSION="null"
PWFILE_URL="https://pwdatacore.hrace009.com/new/"
SERVER_PATH="/home"
PACKAGE_UPGRADE="yum -q -y upgrade"
PACKAGE_UPDATE="yum -q -y update"
PACKAGE_CLEAN="yum -q clean all"
PACKAGE_INSTALLER="yum -q -y install"
SOFTWARE_PCKG_1="redhat-lsb-core ntpdate MariaDB MariaDB-server httpd httpd-tools mod_fcgid fcgi mod_http2 mod_ssl php php-fpm php-mysqlnd php-gd php-imap php-ldap php-mcrypt php-mbstring php-odbc php-pear php-xml php-xmlrpc php-pecl-imagick php-soap php-pecl-zip php-pecl-rar php-pear php-intl php-ioncube-loader perl perl-Net-SSLeay openssl perl-IO-Tty unzip"
SOFTWARE_PCKG_2="glibc.i686 glibc.x86_64 libxml2.i686 libxml2.x86_64 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 libgcc.i686 libgcc.x86_64 pcre.i686 pcre.x86_64 java-1.6.0-openjdk wine p7zip perl-Digest-MD5 perl-Encode-Detect"
HOST_NAME="127.0.0.1   auth aumanager audb manager link1 game1 game2 game3 delivery database backup gmserver dbserver gamedbserver GAuth gdelivery GameDB GameDBClient providerserver6 providerserver7 providerserver8 providerserver9 linkip1 linkip2 linkip3 linkip4"
RPM_IMPORT="rpm --import"
RPM_INSTALL="rpm -ivh"
EPEL_FILE="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
EPEL_KEY="https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7"
REMI_FILE="http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
WEBMIN_KEY="http://www.webmin.com/jcameron-key.asc"
WEBMIN_INSTALL="http://www.webmin.com/download/rpm/webmin-current.rpm"
REMI_KEY="http://rpms.remirepo.net/RPM-GPG-KEY-remi"
MARIADB_KEY="https://yum.mariadb.org/RPM-GPG-KEY-MariaDB"
MARIADB_MIRROR="https://archive.mariadb.org/mariadb-10.1.48/yum/centos7-amd64"
LOGFILE=$(date +%Y-%m-%d_%H.%M.%S_hrace009_Personal_Cloud_install.log)
RED='\033[0;41;30m'
STD='\033[0;0;39m'

pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

server_131(){
	PW_VERSION="1.3.1"
}

server_136(){
	PW_VERSION="1.3.6"
}

server_145(){
	PW_VERSION="1.4.5"
}

server_146(){
	PW_VERSION="1.4.6"
}

server_147(){
	PW_VERSION="1.4.7"
}

server_151(){
	PW_VERSION="1.5.1"
}

server_153(){
	PW_VERSION="1.5.3"
}

server_155(){
	PW_VERSION="1.5.5"
}


show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~"	
	echo " Chose Server Version"
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "1. 1.3.1"
	echo "2. 1.3.6"
	echo "3. 1.4.5"
	echo "4. 1.4.6"
	echo "5. 1.4.7"
	echo "6. 1.5.1"
	echo "7. 1.5.3"
	echo "8. 1.5.5"
	echo "9. Exit"
}

read_options(){
	local choice
	read -p "Enter choice [ 1 - 9] " choice
	case $choice in
		1) server_131 ;;
		2) server_136 ;;
		3) server_145 ;;
		4) server_146 ;;
		5) server_147 ;;
		6) server_151 ;;
		7) server_153 ;;
		8) server_155 ;;
		9) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

touch "$LOGFILE"
exec > >(tee "$LOGFILE")
exec 2>&1

show_menus
read_options

if [ ! -d $SERVER_PATH ]; then
mkdir $SERVER_PATH
fi

#--- Display the 'welcome' splash/user warning info..
echo ""
echo "#############################################################################"
echo "#  Welcome to the Official hrace009 VPS PW Installer $PW_VERSION                  #"
echo "#  This Installer Only for CentOS 7.X, otherwise will not support.          #"
echo "#  Make sure this server is fresh install.                                  #"
echo "#  This application will install hrace009 Perfect World $PW_VERSION               #"
echo "#  For more information, please visit: https://www.hrace009.com             #"
echo "#############################################################################"
sleep 5

echo -e "\nChecking that minimal requirements are ok"

# Ensure the OS is compatible with the launcher
if [ -f /etc/centos-release ]; then
    OS="CentOs"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 6 or 7
fi
ARCH=$(uname -m)

echo "Detected : $OS $VER $ARCH"

if [[ "$OS" = "CentOs" && ("$VER" = "7") ]]; then 
    echo "Your OS Good to go."
else
    echo "Sorry, this OS is not supported by hrace009." 
    exit 1
fi

# Check if the user is 'root' before allowing installation to commence
if [ $UID -ne 0 ]; then
    echo "Install failed: you must be logged in as 'root' to install."
    echo "Use command 'sudo -i', then enter root password and then try again."
    exit 1
fi
echo ""
echo "Please wait a while, we collect some information first."
echo "======================================================="

$PACKAGE_INSTALLER wget bind-utils jwhois yum-priorities yum-utils curl iptables-services

# Flush iptables
iptables --flush
service iptables save
systemctl stop firewalld
systemctl disable firewalld.service

# service iptables stop
systemctl stop iptables.service

local_ip=$(ip addr show | awk '$1 == "inet" && $3 == "brd" { sub (/\/.*/,""); print $2 }')
extern_ip="$(wget -qO- http://api.sentora.org/ip.txt)"

while getopts d:i:t: opt; do
  case $opt in
  d)
      SVR_FQDN=$OPTARG
	  PATCHER_FQDN=$OPTARG
	  REGISTER_FQDN=$OPTARG
      INSTALL="auto"
      ;;
  i)
      PUBLIC_IP=$OPTARG
      if [[ "$PUBLIC_IP" == "local" ]] ; then
          PUBLIC_IP=$local_ip
      elif [[ "$PUBLIC_IP" == "public" ]] ; then
          PUBLIC_IP=$extern_ip
      fi
      ;;
  t)
      echo "$OPTARG" > /etc/timezone
      tz=$(cat /etc/timezone)
      ;;
  esac
done
if [[ ("$SVR_FQDN" != "" && "$PUBLIC_IP" == "") || 
      ("$SVR_FQDN" == "" && "$PUBLIC_IP" != "") ]] ; then
    echo "-d and -i must be both present or both absent."
    exit 2
fi

if [[ ("$PATCHER_FQDN" != "" && "$PUBLIC_IP" == "") || 
      ("$PATCHER_FQDN" == "" && "$PUBLIC_IP" != "") ]] ; then
    echo "-d and -i must be both present or both absent."
    exit 2
fi

if [[ ("$REGISTER_FQDN" != "" && "$PUBLIC_IP" == "") || 
      ("$REGISTER_FQDN" == "" && "$PUBLIC_IP" != "") ]] ; then
    echo "-d and -i must be both present or both absent."
    exit 2
fi
clear
if [[ "$tz" == "" && "$SVR_FQDN" == "" ]] ; then
    # Propose selection list for the time zone
    echo "Preparing to select timezone, please wait a few seconds..."
    $PACKAGE_INSTALLER tzdata
    # setup server timezone
        # make tzselect to save TZ in /etc/timezone
        echo "echo \$TZ > /etc/timezone" >> /usr/bin/tzselect
        tzselect
        tz=$(cat /etc/timezone)
fi
# clear timezone information to focus user on important notice
clear

# Installer parameters
if [[ "$SVR_FQDN" == "" ]] ; then
    echo -e "\n\e[1;33m=== Informations required to build your server ===\e[0m"
    echo 'The installer requires 6 pieces of information:'
    echo ' 1) the GLINK Domain that you want to use for client access on port 29000,'
    echo '   - do not use your main domain (like domain.com)'
    echo '   - use a sub-domain, e.g pwserver.domain.com'
    echo '   - or use the server hostname, e.g server1.domain.com'
    echo '   - DNS must already be configured and pointing to the server IP'
    echo ' 2) the Patcher Domain that you want to use for Auto Patcher on port 80,'
    echo '   - do not use your main domain (like domain.com)'
    echo '   - use a sub-domain, e.g patcher.domain.com'
    echo '   - or use the server hostname, e.g server2.domain.com'
    echo '   - DNS must already be configured and pointing to the server IP'
    echo ' 3) the API Domain that you want to use for API communication on port 80,'
    echo '   - do not use your main domain (like domain.com)'
    echo '   - use a sub-domain, e.g api.domain.com'
    echo '   - or use the server hostname, e.g server1.domain.com'
    echo '   - DNS must already be configured and pointing to the server IP'
    echo ' 4) Special user for your PW Server.'
    echo ' 5) MySQL Admin User and Password for MySQL (DO NOT USE ROOT USER).'
    echo ' 6) The public IP of the server.'
    echo ''

    SVR_FQDN="$(/bin/hostname)"
    PUBLIC_IP=$extern_ip
    while true; do
        echo ""
		echo "Enter your GLINK Domain e.g game.mypw.com"
        read -e -p "GLINK Domain PW Server: " -i "$SVR_FQDN" SVR_FQDN
		echo "Enter your Patcher Domain e.g patcher.mypw.com"
		read -e -p "Patcher Domain PW Server: " -i "$PATCHER_FQDN" PATCHER_FQDN
		echo "Enter your API Domain e.g api.mypw.com"
		read -e -p "API Domain PW Server: " -i "$REGISTER_FQDN" REGISTER_FQDN

        if [[ "$PUBLIC_IP" != "$local_ip" ]]; then
          echo -e "\nThe public IP of the server is $PUBLIC_IP.\nThe local IP is $local_ip"
          echo "For a production server, the PUBLIC IP must be used."
		  echo "For a development server, the LOCAL IP must be used."
        fi  
        read -e -p "Enter (or confirm) the public IP for this server: " -i "$PUBLIC_IP" PUBLIC_IP
        echo ""

        # Checks if the panel domain is a subdomain
        sub=$(echo "$SVR_FQDN" | sed -n 's|\(.*\)\..*\..*|\1|p')
        if [[ "$sub" == "" ]]; then
            echo -e "\e[1;31mWARNING: $SVR_FQDN is not a subdomain!\e[0m"
            confirm="true"
        fi
        sub2=$(echo "$PATCHER_FQDN" | sed -n 's|\(.*\)\..*\..*|\1|p')
        if [[ "$sub2" == "" ]]; then
            echo -e "\e[1;31mWARNING: $PATCHER_FQDN is not a subdomain!\e[0m"
            confirm="true"
        fi
        sub3=$(echo "$REGISTER_FQDN" | sed -n 's|\(.*\)\..*\..*|\1|p')
        if [[ "$sub3" == "" ]]; then
            echo -e "\e[1;31mWARNING: $REGISTER_FQDN is not a subdomain!\e[0m"
            confirm="true"
        fi

        # Checks if the panel domain is already assigned in DNS
        dns_panel_ip=$(host "$SVR_FQDN"|grep address|cut -d" " -f4)
        if [[ "$dns_panel_ip" == "" ]]; then
            echo -e "\e[1;31mWARNING: $SVR_FQDN is not defined in your DNS!\e[0m"
            echo "  You must add records in your DNS manager (and then wait until propagation is done)."
            echo "  If this is a production installation, set the DNS up as soon as possible."
			echo "  If this is a development installation, you can ignore this warning."
            confirm="true"
        else
            echo -e "\e[1;32mOK\e[0m: DNS successfully resolves $SVR_FQDN to $dns_panel_ip"

            # Check if panel domain matches public IP
            if [[ "$dns_panel_ip" != "$PUBLIC_IP" ]]; then
                echo -e -n "\e[1;31mWARNING: $SVR_FQDN DNS record does not point to $PUBLIC_IP!\e[0m"
                echo "  PW Server will not be reachable from http://$SVR_FQDN"
				echo "  For development use, just ignore this warning"
                confirm="true"
            fi
        fi

        dns_panel_ip2=$(host "$PATCHER_FQDN"|grep address|cut -d" " -f4)
        if [[ "$dns_panel_ip2" == "" ]]; then
            echo -e "\e[1;31mWARNING: $PATCHER_FQDN is not defined in your DNS!\e[0m"
            echo "  You must add records in your DNS manager (and then wait until propagation is done)."
            echo "  If this is a production installation, set the DNS up as soon as possible."
			echo "  If this is a development installation, you can ignore this warning."
            confirm="true"
        else
            echo -e "\e[1;32mOK\e[0m: DNS successfully resolves $PATCHER_FQDN to $dns_panel_ip2"

            # Check if panel domain matches public IP
            if [[ "$dns_panel_ip2" != "$PUBLIC_IP" ]]; then
                echo -e -n "\e[1;31mWARNING: $PATCHER_FQDN DNS record does not point to $PUBLIC_IP!\e[0m"
                echo "  PW Server will not be reachable from http://$PATCHER_FQDN"
				echo "  For development use, just ignore this warning"
                confirm="true"
            fi
        fi

        dns_panel_ip3=$(host "$REGISTER_FQDN"|grep address|cut -d" " -f4)
        if [[ "$dns_panel_ip3" == "" ]]; then
            echo -e "\e[1;31mWARNING: $REGISTER_FQDN is not defined in your DNS!\e[0m"
            echo "  You must add records in your DNS manager (and then wait until propagation is done)."
            echo "  If this is a production installation, set the DNS up as soon as possible."
			echo "  If this is a development installation, you can ignore this warning."
            confirm="true"
        else
            echo -e "\e[1;32mOK\e[0m: DNS successfully resolves $REGISTER_FQDN to $dns_panel_ip3"

            # Check if panel domain matches public IP
            if [[ "$dns_panel_ip3" != "$PUBLIC_IP" ]]; then
                echo -e -n "\e[1;31mWARNING: $REGISTER_FQDN DNS record does not point to $PUBLIC_IP!\e[0m"
                echo "  PW Server will not be reachable from http://$REGISTER_FQDN"
				echo "  For development use, just ignore this warning"
                confirm="true"
            fi
        fi

        if [[ "$PUBLIC_IP" != "$extern_ip" && "$PUBLIC_IP" != "$local_ip" ]]; then
            echo -e -n "\e[1;31mWARNING: $PUBLIC_IP does not match detected IP !\e[0m"
            echo "  PW Server will not work with this IP..."
			echo "  For development use, just ignore this warning"
                confirm="true"
        fi
      
        echo ""
        # if any warning, ask confirmation to continue or propose to change
        if [[ "$confirm" != "" ]] ; then
            echo "There are some warnings..."
            echo "Are you really sure that you want to setup PW Server with these parameters?"
            read -e -p "(y):Accept and install, (n):Change domain or IP, (q):Quit installer? " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) continue;;
                [Qq]* ) exit;;
            esac
        else
            read -e -p "All is ok. Do you want to install PW Server now (y/n)? " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) exit;;
            esac
        fi
    done
fi

# Function to disable a file by appending its name with _disabled
disable_file() {
    mv "$1" "$1_disabled_by_hrace009" &> /dev/null
}

#--- Some functions used many times below
# Random password generator function
passwordgen() {
    l=$1
    [ "$l" == "" ] && l=16
    tr -dc A-Za-z0-9 < /dev/urandom | head -c ${l} | xargs
}

# Random username generator function
usernamegen() {
    l=$1
    [ "$l" == "" ] && l=6
    tr -dc a-z < /dev/urandom | head -c ${l} | xargs
}
# Add first parameter in hosts file as local IP domain
add_local_domain() {
    if ! grep -q "127.0.0.1 $1" /etc/hosts; then
        echo "127.0.0.1 $1" >> /etc/hosts;
    fi
}

echo -e "\n\e[1;33m=== Special User Information ===\e[0m"
echo -e "NOTE: If empty user and pass, we will use random generate"
read -e -p "Enter OS Username: " -i "$CREATE_USER" CREATE_USER
read -e -p "Enter OS Password: " -i "$CREATE_USER_PASSWD" CREATE_USER_PASSWD
echo -e "\e[32;3m=== Thank You ===\e[0m"
echo -e "\n\e[1;33m=== MySQL Information ===\e[0m"
echo -e "NOTE: If empty user, pass and DBO, we will use random generate"
read -e -p "Enter MySQL Root Username: " -i "$MYSQL_USER" MYSQL_USER
read -e -p "Enter MySQL Root Password: " -i "$MYSQL_PASSWD" MYSQL_PASSWD
read -e -p "Enter MySQL DBO Name: " -i "$MYSQL_DBO_NAME" MYSQL_DBO_NAME
echo -e "\e[32;3m=== Thank You ===\e[0m"
echo -e "\n\e[1;33m=== Apache Tomcat Port ===\e[0m"
echo -e "NOTE: If empty port number, we will use 55555"
read -e -p "Enter Tomcat Port (e.g 8080): " -i "$TC_PORT" TC_PORT
echo -e "\e[32;3m=== Thank You ===\e[0m"

if [[ $CREATE_USER == "" ]]; then
	CREATE_USER=$(usernamegen);
	echo "Using SSH user \"$CREATE_USER\""
fi

if [[ "$CREATE_USER_PASSWD" == "" ]]; then
	CREATE_USER_PASSWD=$(passwordgen);
	echo "Using SSH password \"$CREATE_USER_PASSWD\""
fi

if [[ "$MYSQL_USER" == "" ]]; then
	MYSQL_USER=$(usernamegen);
	echo "Using mysql root user \"$MYSQL_USER\""
fi

if [[ "$MYSQL_PASSWD" == "" ]]; then
	MYSQL_PASSWD=$(passwordgen);
	echo "Using mysql password \"$MYSQL_PASSWD\""
fi

if [[ "$MYSQL_DBO_NAME" == "" ]]; then
	MYSQL_DBO_NAME=$(usernamegen);
	echo "Using DBO name \"$MYSQL_DBO_NAME\""
fi

if [[ "$TC_PORT" == "" ]]; then
	TC_PORT="55555";
	echo "Using Port 55555 for TOMCAT"
fi

echo -e "\nInstalling Perfect World \e[1;33m$PW_VERSION\n\e[0mServer Domain: \e[1;33mhttp://$SVR_FQDN\n\e[0mPatcher Domain: \e[1;33mhttp://$PATCHER_FQDN\n\e[0mRegister Domain: \e[1;33mhttp://$REGISTER_FQDN\n\e[0mIP: \e[1;33m$PUBLIC_IP\e[0m"
echo -e "OS: \e[1;33m$OS $VER\e[0m"

echo -e "\n\e[1;33m=== Please sit and take coffe break, let me install PW Server $PW_VERSION for you ===\e[0m"
sleep 5
#--- Adapt repositories and packages sources
echo -e "\n\e[1;33m=== Updating repositories and packages sources ===\e[0m"

#Add MariaDB Repo
{
	echo "# MariaDB 10.X CentOS7 repository list - created $(date +%Y-%m-%d_%H.%M.%S)"
	echo "# http://downloads.mariadb.org/mariadb/repositories/"
	echo "[mariadb]"
	echo "name = MariaDB"
	echo "baseurl = $MARIADB_MIRROR"
	echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB"
	echo "gpgcheck=1"
} >> /etc/yum.repos.d/MariaDB.repo

{
	echo "[CodeIT]"
	echo "name=CodeIT repo"
	echo "baseurl=https://repo.codeit.guru/packages/centos/7/\$basearch"
	echo "enabled=1"
	echo "gpgkey=https://repo.codeit.guru/RPM-GPG-KEY-codeit"
	echo "gpgcheck=1"
} >> /etc/yum.repos.d/codeit.el7.repo

{
	echo "[CityFan]"
	echo "name=City Fan Repo"
	echo "baseurl=http://www.city-fan.org/ftp/contrib/yum-repo/rhel\$releasever/\$basearch/"
	echo "enabled=0"
	echo "gpgcheck=0"
} >> /etc/yum.repos.d/cityfan.repo

$RPM_INSTALL $EPEL_FILE
$RPM_INSTALL $REMI_FILE
#$RPM_IMPORT $WEBMIN_KEY
$RPM_IMPORT $EPEL_KEY
$RPM_IMPORT $REMI_KEY
$RPM_IMPORT $MARIADB_KEY
yum-config-manager --enable remi-php72 epel codeit cityfan

#Give Priority EPEL Repo
sed -i -e 's/\]$/\]\npriority=10/g' "/etc/yum.repos.d/"epel*
sed -i 's|priority=[0-9]\+|priority=10|' "/etc/yum.repos.d/"epel*

#Give Priority Remi
sed -i -e 's/\]$/\]\npriority=10/g' "/etc/yum.repos.d/"remi*
sed -i 's|priority=[0-9]\+|priority=10|' "/etc/yum.repos.d/"remi*

#Give Priority MariaDB
sed -i -e 's/\]$/\]\npriority=10/g' "/etc/yum.repos.d/"MariaDB*
sed -i 's|priority=[0-9]\+|priority=10|' "/etc/yum.repos.d/"MariaDB*

#Give Priority CodeIT Repo
sed -i -e 's/\]$/\]\npriority=10/g' "/etc/yum.repos.d/"codeit*
sed -i 's|priority=[0-9]\+|priority=10|' "/etc/yum.repos.d/"codeit*

#Give Priority CityFan Repo
sed -i -e 's/\]$/\]\npriority=10/g' "/etc/yum.repos.d/"cityfan*
sed -i 's|priority=[0-9]\+|priority=10|' "/etc/yum.repos.d/"cityfan*

# We need to disable SELinux...
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

#--- List all already installed packages (may help to debug)
echo -e "\n\e[1;33mListing of all packages installed:\e[0m"
rpm -qa | sort

#--- Ensures that all packages are up to date
echo -e "\n\e[1;33mUpdating+upgrading system, it may take some time...\e[0m"

$PACKAGE_CLEAN
$PACKAGE_UPGRADE
$PACKAGE_UPDATE

echo -e "\n\e[1;33m=== Installing Software Depedency ===\e[0m"
$PACKAGE_INSTALLER $SOFTWARE_PCKG_1
$PACKAGE_INSTALLER $SOFTWARE_PCKG_2
$RPM_INSTALL $WEBMIN_INSTALL
systemctl enable mariadb.service
systemctl enable httpd.service
systemctl enable php-fpm.service
chkconfig webmin on
systemctl start mariadb.service
systemctl start httpd.service
systemctl start php-fpm.service
/etc/init.d/webmin start
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Creating Special Linux Users ===\e[0m"
CREATE_USER_ENC=$(perl -e 'print crypt($ARGV[0], "password")' "$CREATE_USER_PASSWD")
useradd -m -p "$CREATE_USER_ENC" $CREATE_USER
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Extracting PW Server Package ===\e[0m"
until wget -q -O /usr/local/src/Core."$PW_VERSION".7z "$PWFILE_URL"Core."$PW_VERSION".7z; do
echo "Transfer failed, retrying in 10 seconds..."
sleep 10
done
7za x /usr/local/src/Core."$PW_VERSION".7z -o$SERVER_PATH/$CREATE_USER -y > $SERVER_PATH/$CREATE_USER/pwserver.log
rm $SERVER_PATH/$CREATE_USER/pwserver.log
rm /usr/local/src/Core."$PW_VERSION".7z
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Linking Lib ===\e[0m"
ln -s $SERVER_PATH/$CREATE_USER/Core/etc/pkcs11.cfg /etc/pkcs11.cfg
ln -s $SERVER_PATH/$CREATE_USER/Core/etc/authd.conf /etc/authd.conf
ln -s $SERVER_PATH/$CREATE_USER/Core/etc/GMserver.conf /etc/GMserver.conf
ln -s $SERVER_PATH/$CREATE_USER/Core/etc/iweb.conf /etc/iweb.conf
ln -s $SERVER_PATH/$CREATE_USER/Core/etc/gmopgen.xml /etc/gmopgen.xml
ln -s $SERVER_PATH/$CREATE_USER/Core/etc/table.xml /etc/table.xml
ln -s $SERVER_PATH/$CREATE_USER/Core/ssl/private /etc/ssl/private
ln -s $SERVER_PATH/$CREATE_USER/Core/ssl/world2_java_gamemanager.keystore /etc/ssl/world2_java_gamemanager.keystore
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so.2 /lib/libtask.so.2
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so /lib/libtask.so
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libstdc++.so.5 /lib/libstdc++.so.5
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so /lib64/libtask.so
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so.2 /lib64/libtask.so.2
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libstdc++.so.5 /lib64/libstdc++.so.5
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libpcre.so.0 /usr/lib/libpcre.so.0
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so.2 /usr/lib/libtask.so.2
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so /usr/lib/libtask.so
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libpcre.so.0 /usr/lib64/libpcre.so.0
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so.2 /usr/lib64/libtask.so.2
ln -s $SERVER_PATH/$CREATE_USER/Core/lib/libtask.so /usr/lib64/libtask.so
sleep 1
echo -e "\n\e[32;3m=== DONE ===\e[0m"
sleep 5

#--- Prepare hostname
# In file hostname
echo "$SVR_FQDN" > /etc/hostname
old_hostname=$(cat /etc/hostname)

# In file hosts
sed -i "/127.0.1.1[\t ]*$old_hostname/d" /etc/hosts
sed -i "s|$old_hostname|$SVR_FQDN|" /etc/hosts
echo "$HOST_NAME" >> /etc/hosts

# For current session
hostname "$SVR_FQDN"

# In network file
{
	echo "NETWORKING=yes"
	echo "HOSTNAME=$SVR_FQDN"
} >> /etc/sysconfig/network
systemctl restart network.service

echo -e "\n\e[1;33m=== Configure Web Server ===\e[0m"
mkdir -p /opt/Website/conf
disable_file /etc/httpd/conf.modules.d/01-cgi.conf
disable_file /etc/httpd/conf.modules.d/00-lua.conf
disable_file /etc/httpd/conf.modules.d/00-dav.conf
sed -i -e "/LoadModule mpm_prefork_module/ s/^#*/# /" "/etc/httpd/conf.modules.d/00-mpm.conf"
sed -i -e "/#LoadModule mpm_event_module/ s/^#*//" "/etc/httpd/conf.modules.d/00-mpm.conf"
echo -e "\nInclude /opt/Website/conf/vHost.conf" >> /etc/httpd/conf/httpd.conf
sed -i -e "/Listen 80/ s/^#*/# /" "/etc/httpd/conf/httpd.conf"
sed -i -e "/AddType text\/html .php/ s/^#*/# /" "/etc/httpd/conf.d/php.conf"
sed -i -e "/DirectoryIndex index.php/q" "/etc/httpd/conf.d/php.conf"
echo -e "\n<FilesMatch \.php$>
	 SetHandler \"proxy:unix:$SERVER_PATH/$CREATE_USER/run/$CREATE_USER-php56-fpm.sock|fcgi://localhost/\"
</FilesMatch>" >> /etc/httpd/conf.d/php.conf

#Add Default VHost
{
	echo "######### Default VHOST ##########"
	echo "ServerName localhost"
	echo "User $CREATE_USER"
	echo "Group $CREATE_USER"
	echo "<Directory $SERVER_PATH/$CREATE_USER/Website/html/default>"
	echo "    Options +FollowSymLinks"
	echo "    DirectoryIndex index.php"
	echo "    deny from all"
	echo "    <IfModule mod_php5.c>"
	echo "        AddType application/x-httpd-php .php"
	echo "        php_flag magic_quotes_gpc Off"
	echo "        php_flag track_vars On"
	echo "        php_flag register_globals Off"
	echo "        php_admin_value upload_tmp_dir $SERVER_PATH/$CREATE_USER/Website/temp"
	echo "    </IfModule>"
	echo "</Directory>"
	echo ""
	echo "ServerTokens Prod"
	echo "Include /opt/Website/conf/AllVhost.conf"
} >> /opt/Website/conf/vHost.conf

#Add VHost
{
	echo "######### Default VHOST $SVR_FQDN ##########"
	echo "NameVirtualHost *:80"
	echo "Listen 80"
	echo "<VirtualHost *:80>"
	echo "ServerAdmin $CREATE_USER@$SVR_FQDN"
	echo "DocumentRoot \"$SERVER_PATH/$CREATE_USER/Website/html/default\""
	echo "ServerName $SVR_FQDN"
	echo "ErrorLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$SVR_FQDN-error.log\""
	echo "CustomLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$SVR_FQDN-access.log\" combined"
	echo "CustomLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$SVR_FQDN-bandwidth.log\" common"
	echo "AddType application/x-httpd-php .php"
	echo "<Directory \"$SERVER_PATH/$CREATE_USER/Website/html/default\">"
	echo "Options +FollowSymLinks -Indexes"
	echo "    AllowOverride All"
	echo "    Order allow,deny"
	echo "    Allow from all"
	echo "    Require all granted"
	echo "</Directory>"
	echo "</VirtualHost>"
	echo ""
	echo "######### Default VHOST $REGISTER_FQDN ##########"
	echo "<virtualhost *:80>"
	echo "ServerName $REGISTER_FQDN"
	echo "ServerAdmin $CREATE_USER@$REGISTER_FQDN"
	echo "DocumentRoot \"$SERVER_PATH/$CREATE_USER/Website/html/server\""
	echo "php_admin_value open_basedir \"$SERVER_PATH/$CREATE_USER/Website/html/server:$SERVER_PATH/$CREATE_USER/Website/temp/\""
	echo "php_admin_value suhosin.executor.func.blacklist \"passthru, show_source, shell_exec, system, pcntl_exec, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid, escapeshellcmd, escapeshellarg, exec\""
	echo "ErrorLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$REGISTER_FQDN-error.log\""
	echo "CustomLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$REGISTER_FQDN-access.log\" combined"
	echo "CustomLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$REGISTER_FQDN-bandwidth.log\" common"
	echo "<Directory \"$SERVER_PATH/$CREATE_USER/Website/html/server\">"
	echo "  Options +FollowSymLinks -Indexes"
	echo "  AllowOverride All"
	echo "  Order Allow,Deny"
	echo "  Allow from all"
	echo "  Require all granted"
	echo "</Directory>"
	echo "AddType application/x-httpd-php .php3 .php"
	echo "DirectoryIndex index.html index.htm index.php index.asp index.aspx index.jsp index.jspa index.shtml index.shtm"
	echo "</virtualhost>"
	echo ""
	echo "######### Default VHOST $PATCHER_FQDN ##########"
	echo "<virtualhost *:80>"
	echo "ServerName $PATCHER_FQDN"
	echo "ServerAdmin $CREATE_USER@$PATCHER_FQDN"
	echo "DocumentRoot \"$SERVER_PATH/$CREATE_USER/Website/html/patcher\""
	echo "php_admin_value open_basedir \"$SERVER_PATH/$CREATE_USER/Website/html/patcher:$SERVER_PATH/$CREATE_USER/Website/temp/\""
	echo "php_admin_value suhosin.executor.func.blacklist \"passthru, show_source, shell_exec, system, pcntl_exec, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid, escapeshellcmd, escapeshellarg, exec\""
	echo "ErrorLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$PATCHER_FQDN-error.log\""
	echo "CustomLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$PATCHER_FQDN-access.log\" combined"
	echo "CustomLog \"$SERVER_PATH/$CREATE_USER/Website/logs/$PATCHER_FQDN-bandwidth.log\" common"
	echo "<Directory \"$SERVER_PATH/$CREATE_USER/Website/html/patcher\">"
	echo "  Options +FollowSymLinks -Indexes"
	echo "  AllowOverride All"
	echo "  Order Allow,Deny"
	echo "  Allow from all"
	echo "  Require all granted"
	echo "</Directory>"
	echo "AddType application/x-httpd-php .php3 .php"
	echo "DirectoryIndex index.html index.htm index.php index.asp index.aspx index.jsp index.jspa index.shtml index.shtm"
	echo "</virtualhost>"
} >> /opt/Website/conf/AllVhost.conf

#Configure FPM
rm /etc/php-fpm.d/www.conf
mkdir -p /home/$CREATE_USER/run/
chown -R $CREATE_USER:$CREATE_USER $SERVER_PATH/$CREATE_USER/run
{
	echo "[$CREATE_USER]"
	echo "user = $CREATE_USER"
	echo "group = $CREATE_USER"
	echo "listen = $SERVER_PATH/$CREATE_USER/run/$CREATE_USER-php56-fpm.sock"
	echo "listen.owner = $CREATE_USER"
	echo "listen.group = $CREATE_USER"
	echo "listen.allowed_clients = 127.0.0.1"
	echo "pm = dynamic"
	echo "pm.max_children = 5"
	echo "pm.start_servers = 2"
	echo "pm.min_spare_servers = 2"
	echo "pm.max_spare_servers = 4"
	echo "pm.max_requests = 200"
	echo "slowlog = $SERVER_PATH/$CREATE_USER/Website/logs/fpm-slow.log"
	echo "php_admin_value[error_log] = $SERVER_PATH/$CREATE_USER/Website/logs/fpm-error.log"
	echo "php_admin_flag[log_errors] = on"
	echo "php_value[session.save_handler] = files"
	echo "php_value[session.save_path]    = $SERVER_PATH/$CREATE_USER/Website/session"
	echo "php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache"
} >> /etc/php-fpm.d/$CREATE_USER.conf

sed -i "s|SERVER_NAME|$SVR_FQDN|g" "/opt/Website/conf/AllVhost.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "/opt/Website/conf/AllVhost.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "/opt/Website/conf/vHost.conf"
sed -i "s|REGISTRATION_DOMAIN|$REGISTER_FQDN|g" "/opt/Website/conf/AllVhost.conf"
sed -i "s|PATCHER_DOMAIN|$PATCHER_FQDN|g" "/opt/Website/conf/AllVhost.conf"
chown -R $CREATE_USER:$CREATE_USER $SERVER_PATH/$CREATE_USER/Website
systemctl stop mariadb.service
systemctl start mariadb.service
systemctl stop httpd.service
systemctl start httpd.service
systemctl stop php-fpm.service
systemctl start php-fpm.service
/etc/init.d/webmin start
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Setup MySQL Data Base ===\e[0m"
MY_CNF_PATH="/etc/my.cnf.d/server.cnf"
DBO_PATH="$SERVER_PATH/$CREATE_USER/MySQL/hrace009_dbo.sql"
sed -i "s|hrace009|$MYSQL_USER|g" $DBO_PATH
mysqlpassword=$(passwordgen);
mysql_dbo_user="dbo"
mysql_dbo_pass=$(passwordgen);

# setup mysql root password
mysqladmin -u root password "$mysqlpassword"

# small cleaning of mysql access
mysql -u root -p"$mysqlpassword" -e "DELETE FROM mysql.user WHERE User='root' AND Host != 'localhost'";
mysql -u root -p"$mysqlpassword" -e "DELETE FROM mysql.user WHERE User=''";
mysql -u root -p"$mysqlpassword" -e "FLUSH PRIVILEGES";

# remove test table that is no longer used
mysql -u root -p"$mysqlpassword" -e "DROP DATABASE IF EXISTS test";

# secure SELECT "hacker-code" INTO OUTFILE 
sed -i "s|\[mysqld\]|&\nsecure-file-priv = /var/tmp|" $MY_CNF_PATH
sed -i "s|\[mariadb\]|&\nsecure-file-priv = /var/tmp|" "/etc/my.cnf.d/server.cnf"
sed -i "s|\[mariadb-10.1\]|&\nsecure-file-priv = /var/tmp|" "/etc/my.cnf.d/server.cnf"

#setup DBO
mysql -u root -p"$mysqlpassword" -e "CREATE DATABASE $MYSQL_DBO_NAME"
mysql -u root -p"$mysqlpassword" "$MYSQL_DBO_NAME" < "$DBO_PATH"
rm -R $SERVER_PATH/$CREATE_USER/MySQL

#Create MYSQL ADMIN USER and Grant All Access like root from all Host
mysql -u root -p"$mysqlpassword" -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWD'";
mysql -u root -p"$mysqlpassword" -e "GRANT GRANT OPTION ON *.* TO '$MYSQL_USER'@'%'";
mysql -u root -p"$mysqlpassword" -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER ON *.* TO '$MYSQL_USER'@'%'";
mysql -u root -p"$mysqlpassword" -e "FLUSH PRIVILEGES";

#Create MYSQL DBO Perfect World
mysql -u root -p"$mysqlpassword" -e "CREATE USER '$mysql_dbo_user'@'localhost' IDENTIFIED BY '$mysql_dbo_pass'";
mysql -u root -p"$mysqlpassword" -e "GRANT SELECT ON *.* TO '$mysql_dbo_user'@'localhost'";
mysql -u root -p"$mysqlpassword" -e "GRANT SELECT, INSERT, UPDATE, REFERENCES, DELETE, CREATE, DROP, ALTER, INDEX, TRIGGER, CREATE VIEW, SHOW VIEW, EXECUTE, ALTER ROUTINE, CREATE ROUTINE, CREATE TEMPORARY TABLES, LOCK TABLES, EVENT ON $MYSQL_DBO_NAME.* TO '$mysql_dbo_user'@'localhost'";
mysql -u root -p"$mysqlpassword" -e "GRANT GRANT OPTION ON $MYSQL_DBO_NAME.* TO '$mysql_dbo_user'@'localhost'";
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Configure PW Admin ===\e[0m"
hashpassword=$(echo -n "$CREATE_USER_PASSWD"| md5sum | awk '{print $1}')
sed -i "s|DB_HOST|localhost|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/webapps/Admin_Control1/WEB-INF/.pwadminconf.jsp"
sed -i "s|DB_USER|$mysql_dbo_user|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/webapps/Admin_Control1/WEB-INF/.pwadminconf.jsp"
sed -i "s|DB_PASSWORD|$mysql_dbo_pass|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/webapps/Admin_Control1/WEB-INF/.pwadminconf.jsp"
sed -i "s|DB_NAME|$MYSQL_DBO_NAME|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/webapps/Admin_Control1/WEB-INF/.pwadminconf.jsp"
sed -i "s|PW_PATH|$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/webapps/Admin_Control1/WEB-INF/.pwadminconf.jsp"
sed -i "s|MD5_PASSWORD|$hashpassword|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/webapps/Admin_Control1/WEB-INF/.pwadminconf.jsp"
sed -i "s|PWCATALINA|$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/tomcat"
sed -i "s|USER_PROCES_PW|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/webapps/Admin_Control1/serverctrl.jsp"
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Configure Apache Tomcat ===\e[0m"
sed -i "s|TC_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/conf/tomcat-users.xml"
sed -i "s|TC_PASSWORD|$CREATE_USER_PASSWD|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/conf/tomcat-users.xml"
sed -i "s|TC_PORT|$TC_PORT|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/conf/server.xml"
chmod 750 $SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/tomcat
ln -s $SERVER_PATH/$CREATE_USER/Core/Wanmei2015/apache-tomcat-7.0.32/tomcat /etc/init.d/tomcat
chkconfig tomcat on
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Configure AUTH ===\e[0m"
sed -i "s|DB_HOST|localhost|g" "$SERVER_PATH/$CREATE_USER/Core/etc/table.xml"
sed -i "s|DB_NAME|$MYSQL_DBO_NAME|g" "$SERVER_PATH/$CREATE_USER/Core/etc/table.xml"
sed -i "s|DB_USER|$mysql_dbo_user|g" "$SERVER_PATH/$CREATE_USER/Core/etc/table.xml"
sed -i "s|DB_PASSWORD|$mysql_dbo_pass|g" "$SERVER_PATH/$CREATE_USER/Core/etc/table.xml"
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Configure PW Path ===\e[0m"
sed -i "s|USER_PROCESS|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Start"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Start"
sed -i "s|USER_GROUP|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Start"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Start_Mini"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Stop"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/authd/build/authd"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamed/gs.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamed/gs_rollback.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamed/gsalias.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamedbd/cashstat.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamedbd/fix.sh"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamedbd/gamesys.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gdeliveryd/gamesys.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gfactiond/gamesys.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gfactiond/gamesys.conf.central"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/glinkd/gamesys.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/logservice/logservice.conf"
sed -i "s|CREATE_USER|$CREATE_USER|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/uniquenamed/gamesys.conf"
if  [[ "$VER" = "7" ]]; then
	sed -i "s|COMMAND_HTTPD|\"systemctl start httpd.service\"|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Start"
	sed -i "s|COMMAND_HTTPD|\"systemctl stop httpd.service\"|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Stop"
else
	sed -i "s|COMMAND_HTTPD|\"/etc/init.d/httpd start\"|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Start"
	sed -i "s|COMMAND_HTTPD|\"/etc/init.d/httpd stop\"|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/Stop"
fi
echo -e "\n\e[32;3m=== DONE ===\e[0m"

echo -e "\n\e[1;33m=== Configure GLINKD ===\e[0m"
sed -i "s|PUBLIC_IP|$PUBLIC_IP|g" "$SERVER_PATH/$CREATE_USER/Core/Wanmei2015/glinkd/gamesys.conf"
echo -e "\n\e[32;3m=== DONE ===\e[0m"

if  [[ "$VER" = "7" ]]; then
	systemctl stop mariadb.service
	systemctl start mariadb.service
	systemctl stop php-fpm.service
	systemctl start php-fpm.service
	systemctl stop httpd.service
	systemctl start httpd.service
else
	/etc/init.d/mysql restart
	/etc/init.d/php-fpm restart
	/etc/init.d/httpd restart
fi
/etc/init.d/webmin restart

echo -e "\n\e[1;33m=== Setup Firewall ===\e[0m"
iptables -A INPUT -p icmp -j ACCEPT 
iptables -A INPUT -i lo -j ACCEPT 
iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT 
iptables -A INPUT -p tcp -m tcp --dport 80 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -m state --state NEW -j ACCEPT 
iptables -A INPUT -p tcp -m tcp --dport 3306 -m state --state NEW -j ACCEPT 
iptables -A INPUT -p tcp -m tcp --dport 10000 -m state --state NEW -j ACCEPT 
iptables -A INPUT -p tcp -m tcp --dport 29000 -m state --state NEW -j ACCEPT 
iptables -A INPUT -p tcp -m tcp --dport $TC_PORT -m state --state NEW -j ACCEPT 
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
iptables -A INPUT -j DROP 
iptables -A FORWARD -j REJECT --reject-with icmp-host-prohibited
service iptables save
systemctl stop iptables.service
systemctl start iptables.service
systemctl enable iptables.service
echo -e "\n\e[32;3m=== DONE ===\e[0m"
echo ""
echo -e "\n\e[1;33m=== Setup File Permision ===\e[0m"
chmod -R 750 /home/$CREATE_USER/Core
chmod -R 750 /home/$CREATE_USER/Website
chown -R $CREATE_USER:$CREATE_USER /home/$CREATE_USER
echo -e "\n\e[32;3m=== DONE ===\e[0m"
echo ""
#--- Store the passwords for user reference
{
	echo "Please Visit: https://www.hrace009.com for more information"
	echo ""
	echo "Common Details"
	echo "=============="
    echo "Server IP address: $PUBLIC_IP"
    echo "Server URL: http://$SVR_FQDN"
    echo "Patcher URL: http://$PATCHER_FQDN"
    echo "Register URL: http://$REGISTER_FQDN"
	echo "Webmin URL: https://$SVR_FQDN:10000"
    echo ""
	echo "Database Details"
	echo "================"
    echo "MySQL Root User: $MYSQL_USER"
    echo "MySQL Root Password: $MYSQL_PASSWD"
    echo "MySQL PW DB User: $mysql_dbo_user"
    echo "MySQL PW DB Password: $mysql_dbo_pass"
	echo "MySQL Remote Port: 3306"
    echo ""
	echo "SSH Details"
	echo "==========="
    echo "SSH User: $CREATE_USER"
    echo "SSH User Password: $CREATE_USER_PASSWD"
    echo ""
	echo "PW Admin Details"
	echo "================"
    echo "PW Admin Password: $CREATE_USER_PASSWD"
	echo "PW Admin URL: http://$PUBLIC_IP:$TC_PORT/Admin_Control1/"
	echo ""
	echo "iWeb Details"
	echo "============"
	echo "Iweb URL: http://$PUBLIC_IP:$TC_PORT/iweb/"
    echo "iWeb User Name: $CREATE_USER-iweb"
    echo "iWeb Password: $CREATE_USER_PASSWD"
	echo ""
	echo "Developer Information"
	echo "====================="
	echo "Root PW Server Path: $SERVER_PATH/$CREATE_USER"
	echo "PW Server Path: $SERVER_PATH/$CREATE_USER/Core/Wanmei2015/"
	echo "All Element data path: $SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamed/config/ELEMENTS"
	echo ""
	echo "Website Development Information"
	echo "==============================="
	echo "Default Path: $SERVER_PATH/$CREATE_USER/Website/default"
	echo "Patcher Path: $SERVER_PATH/$CREATE_USER/Website/patcher"
	echo "API/Register Path: $SERVER_PATH/$CREATE_USER/Website/server"
} >> /root/Installation_Document.txt

#--- Advise the admin that PW SERVER is now installed and accessible.
{
echo "###########################################################"
echo " Congratulations hrace009 Perfect World $PW_VERSION"
echo " has now been installed on your server. "
echo " Please review the log file left in /root/ for "
echo " any errors encountered during installation."
echo "###########################################################"
echo "Please Visit: https://www.hrace009.com for more information"
echo "###########################################################"
echo ""
echo -e "\e[1;33mCommon Details\e[0m"
echo -e "\e[1;33m==============\e[0m"
echo "Server IP address: $PUBLIC_IP"
echo "Server URL: http://$SVR_FQDN"
echo "Patcher URL: http://$PATCHER_FQDN"
echo "Register URL: http://$REGISTER_FQDN"
echo "Webmin URL: https://$SVR_FQDN:10000"
echo ""
echo -e "\e[1;33mDatabase Details\e[0m"
echo -e "\e[1;33m================\e[0m"
echo "MySQL Root User: $MYSQL_USER"
echo "MySQL Root Password: $MYSQL_PASSWD"
echo "MySQL PW DB User: $mysql_dbo_user"
echo "MySQL PW DB Password: $mysql_dbo_pass"
echo "MySQL Remote Port: 3306"
echo ""
echo -e "\e[1;33mSSH Details\e[0m"
echo -e "\e[1;33m===========\e[0m"
echo "SSH User: $CREATE_USER"
echo "SSH User Password: $CREATE_USER_PASSWD"
echo ""
echo -e "\e[1;33mPW Admin Details\e[0m"
echo -e "\e[1;33m================\e[0m"
echo "PW Admin Password: $CREATE_USER_PASSWD"
echo "PW Admin URL: http://$PUBLIC_IP:$TC_PORT/Admin_Control1/"
echo ""
echo -e "\e[1;33miWeb Details\e[0m"
echo -e "\e[1;33m============\e[0m"
echo "Iweb URL: http://$PUBLIC_IP:$TC_PORT/iweb/"
echo "iWeb User Name: $CREATE_USER-iweb"
echo "iWeb Password: $CREATE_USER_PASSWD"
echo ""
echo -e "\e[1;33mDeveloper Information\e[0m"
echo -e "\e[1;33m=====================\e[0m"
echo "Root PW Server Path: $SERVER_PATH/$CREATE_USER"
echo "PW Server Path: $SERVER_PATH/$CREATE_USER/Core/Wanmei2015/"
echo "All Element data path: $SERVER_PATH/$CREATE_USER/Core/Wanmei2015/gamed/config/ELEMENTS"
echo ""
echo -e "\e[1;33mWebsite Development Information\e[0m"
echo -e "\e[1;33m===============================\e[0m"
echo "Default Path: $SERVER_PATH/$CREATE_USER/Website/default"
echo "Patcher Path: $SERVER_PATH/$CREATE_USER/Website/patcher"
echo "API/Register Path: $SERVER_PATH/$CREATE_USER/Website/server"
echo ""
echo -e "\e[1;33m#####################################################################\e[0m"
echo -e "\e[1;33m (theses documentation are saved in /root/Installation_Document.txt)\e[0m"
echo -e "\e[1;33m#####################################################################\e[0m"
echo ""
} &>/dev/tty
shutdown -r now
