
set -o nounset


## colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly BLUE='\033[0;34m'
readonly WHITE='\033[1;37m'
readonly ORANGE='\033[0;33m'
readonly YELLOW='\033[1;33m'
readonly PURPLE='\033[0;35m'
readonly NOCO='\033[0m'

COLOR_ARR=()
COLOR_ARR+=("$NOCO")
COLOR_ARR+=("$RED")
COLOR_ARR+=("$GREEN")
COLOR_ARR+=("$CYAN")
COLOR_ARR+=("$BLUE")
COLOR_ARR+=("$WHITE")
COLOR_ARR+=("$ORANGE")


deps()
{
    local result=$(apt-cache showpkg $1)
    local rdepsStartLine=$(echo "$result" | grep -n "^Reverse Depends:" | awk -F ':' '{print $1}')
    local depsStartLine=$(echo "$result" | grep -n "^Dependencies:" | awk -F ':' '{print $1}')
    local providesStartLine=$(echo "$result" | grep -n "^Provides:" | awk -F ':' '{print $1}') 
    local rdepsFirstLine=$((rdepsStartLine+1))
    local rdepsLastLine=$((depsStartLine-1))
    local depsFirstLine=$((depsStartLine+1))
    local depsLastLine=$((providesStartLine-1))

    
    echo -e "${YELLOW}Reverse Depends:${NOCO}"
    if [ "$rdepsFirstLine" -le "$rdepsLastLine" ];then
	local rdeps=$(echo "$result" | sed -n "$rdepsFirstLine,$rdepsLastLine p") 
	while read -r line;do
	    local packageName=$(echo $line | awk -F ',' '{print $1}')
	    local depsVersion=$(echo $line | awk -F ',' '{print $2}')
	    echo -e "\t${GREEN}$packageName  ${PURPLE}===>  ${CYAN}$depsVersion${NOCO}"
	done <<< "$rdeps"
    else 
	echo -e "\t${RED}None${NOCO}"
    fi

    echo -e "${YELLOW}Dependencies:${NOCO}"
    if [ "$depsFirstLine" -le "$depsLastLine" ];then
	deps=$(echo "$result" | sed -n "$depsFirstLine,$depsLastLine p")
	while read -r line;do
	    local packageVersion=$(echo $line | awk  '{print $1}')
	    echo -e "\t${BLUE}Version : $packageVersion${NOCO}"
	    local fieldCount=$(echo $line | awk '{print NF}')
	    for i in $(seq 3 3 $fieldCount)
	    do
		local packageName=$(echo $line | awk  '{print $'${i}'}')
		local numberIndex=$((i+1))
		local versionIndex=$((i+2))
		local number=$(echo $line | awk '{print $'${numberIndex}'}')
		local version=$(echo $line | awk '{print $'${versionIndex}'}')		
		echo -e "\t\t${GREEN}$packageName ${PURPLE}$number ${CYAN}$version${NOCO}"
	    done
	done <<< "$deps"
    fi
    
}

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
	deps)
	    deps $2
	    ;;
	*)
    esac
}	


main "$@"
