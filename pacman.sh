
set -o nounset


## colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
ORANGE='\033[0;33m'
NOCO='\033[0m'

COLOR_ARR=()
COLOR_ARR+=("$NOCO")
COLOR_ARR+=("$RED")
COLOR_ARR+=("$GREEN")
COLOR_ARR+=("$CYAN")
COLOR_ARR+=("$BLUE")
COLOR_ARR+=("$WHITE")
COLOR_ARR+=("$ORANGE")


files()
{
    result=$(dpkg-query -L $1 2>/dev/null)

    if [ $? -eq 1 ];then
	echo -e "${RED} package '$1' not installed${NOCO}"
    else
	if [[ $result == *"does not contain any files"* ]];then
	    echo -e "${RED}package '$1' does not containe any files${NOCO}"
	fi	    
    fi

    while read -r line;do
	slashs="${line//[^\/]}"
	slashCount=${#slashs}
	spaceCount=$((slashCount-1))
	if [ "$spaceCount" -gt 0 ];then
	    printf "%0.s\t" $(seq 1 $spaceCount)
	fi
	echo -e "${COLOR_ARR[$slashCount]}$line${NOCO}"
    done <<< "$result"

}


search()
{
    result=$(apt-cache search $1)
    while IFS=' ' read -ra line; do
	pkg_name=${line[0]}
	pkg_info=$(apt-cache show $pkg_name)
	pkg_section=$(echo "$pkg_info" | grep -m 1 '^Section:' | awk '{print $2}')
	pkg_version=$(echo "$pkg_info" | grep -m 1 '^Version:' | awk '{print $2}')
	pkg_size=$(echo "$pkg_info" | grep -m 1 '^Size:' | awk '{print $2}')
	pkg_desc=$(echo "$pkg_info" | grep -m 1 '^Description-en:\|Description:' | awk  '{sub(/[^ ]+ /, ""); print $0}')
	
	echo -en "${BLUE}[$pkg_section]${NOCO}/${GREEN}$pkg_name${NOCO} ${CYAN}$pkg_version${NOCO}"
	dpkg -s $pkg_name 1>/dev/null 2>&1
	if [ $? -eq 0 ];then
	    echo -e " ${ORANGE}[installed]${NOCO}"
	else
	    echo ""
	fi
	echo -e "\t$pkg_desc"
    done <<< "$result"
}



main()
{
    case "$1" in 
	search)
	    search $2
	    ;;
	files)
	    files $2
	    ;;
	*)
    esac
}	


main "$@"
