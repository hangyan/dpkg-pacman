#!/usr/bin/env bash


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


info()
{
    local result=$(apt-cache show $1)
    readonly alignCol=24
    local desc=""
    while read -r line;do
	echo $line | awk '{print $1}' | grep ".*:" > /dev/null 2>&1
	if [ $? -eq 1 ];then
	    desc="$desc\n$line"
	    continue
	fi
	local fieldName=$(echo $line | awk -F ":" '{print $1}')
	local fieldNameLen=${#fieldName}
	local padding=$((alignCol-fieldNameLen))
	local contents=$(echo $line | awk -F ":" '{$1="";print}')
	echo -en "${BLUE}$fieldName:"
	for i in $(seq 1 $padding);do echo -n " ";done
	echo -e  "${GREEN}$contents${NOCO}"
    done <<< "$result"

    for i in $(seq 1 $alignCol); do echo -ne "${BLUE}-";done
    echo -e "${CYAN}$desc${NOCO}\n"
}


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
    local result=$(dpkg-query -L $1 2>/dev/null)

    if [ $? -eq 1 ];then
	echo -e "${RED} package '$1' not installed${NOCO}"
    else
	if [[ $result == *"does not contain any files"* ]];then
	    echo -e "${RED}package '$1' does not containe any files${NOCO}"
	fi	    
    fi

    while read -r line;do
	local slashs="${line//[^\/]}"
	local slashCount=${#slashs}
	local spaceCount=$((slashCount-1))
	if [ "$spaceCount" -gt 0 ];then
	    printf "%0.s\t" $(seq 1 $spaceCount)
	fi
	echo -e "${COLOR_ARR[$slashCount]}$line${NOCO}"
    done <<< "$result"

}


search()
{
    local result=$(apt-cache search $1)
    
    if [ "$result" == "" ];then
	echo -e "${RED}No package found${NOCO}"
	return
    fi
    
    while IFS=' ' read -ra line; do
	local pkgName=${line[0]}
	local pkgInfo=$(apt-cache show $pkgName)
	local pkgSection=$(echo "$pkgInfo" | grep -m 1 '^Section:' | awk '{print $2}')
	local pkgVersion=$(apt-cache policy $1 | grep  "\*\*\*"  | awk '{print $2}')
	if [ -z "$pkgVersion" ];then
	    pkgVersion=$(echo "$pkgInfo" | grep -m 1 '^Version:' | awk '{print $2}')
	fi
	local pkgSize=$(echo "$pkgInfo" | grep -m 1 '^Size:' | awk '{print $2}')
	local pkgDesc=$(echo "$pkgInfo" | grep -m 1 '^Description-en:\|Description:' | awk  '{sub(/[^ ]+ /, ""); print $0}')
	
	echo -en "${BLUE}[$pkgSection]${NOCO}/${GREEN}$pkgName${NOCO} ${CYAN}$pkgVersion${NOCO}"
	dpkg -s $pkgName 1>/dev/null 2>&1
	if [ $? -eq 0 ];then
	    echo -e " ${ORANGE}[installed]${NOCO}"
	else
	    echo ""
	fi
	echo -e "\t$pkgDesc"
    done <<< "$result"
}

usage()
{
    cat <<PACMAN_USAGE

Usage: $0 {search|files|info|deps} pkgname

    search : search package
    info   : show information about package
    files  : list files of a installed'package 
    deps   : show package's deps
PACMAN_USAGE

exit 1

}
main()
{
    if [ $# -ne 2 ];then
	usage
    fi

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
	info)
	    info $2
	    ;;
	*)
	    usage
	    ;;
    esac
}	


main "$@"
