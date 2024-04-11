#!/usr/bin/env bash
#
#AUTHER: TJ
#USAGE: CTFstarter.sh <CTFname> <ipaddress>
#

#UNCOMMENT TO ENTER DEBUG MODE
#set -x

#GLOBLE VARIABLES

name=$1
IP=$2
NUM_OF_ARG=$#
OK=true
wordlist="/usr/share/wordlists/dirb/comman.txt"

#TO CHECK WHETHER THE GIVEN IP IS PINGING WELL

ping_checking=0
isPinging () {
	echo "[+] $IP Pinging..."
	if ping -c 3 $1 &> /dev/null ; then
		echo "[+] $IP Pinging...[Done]"
		ping_checking=1
	else
		echo "[+] $IP Pinging...[Fail]"
		ping_checking=0
	fi
}

#USER INPUT VALIDATAING 

input_validation=0
inputValidation () {
	echo "[+] Validating User Input..."
	if ((${NUM_OF_ARG} > 2)); then 
		echo "[+] Validating User Input...[Fail]"
		echo "[!] Invalid usage of parameters"
		echo "[>] Usage: startCTF <CTFname> <IP>"
		input_validation=0
		exit 1
	else
		A=`echo $IP | awk '/^([0-9]{1,3}[.]){3}([0-9]{1,3})$/{print $1}'`
		if [ $A ]; then
			echo "[+] Validating User Input...[Done]"
			input_validation=1
		else
			echo "[+] Validating User Input...[Fail]"
			echo "[!] Invalid IP address"
			echo "[>] Check IP address again"
			input_validation=0
		fi
	fi
}

# dig -x 192.229.179.87 | grep -v ";" | awk '{ print $5 }' | sort -u
#VALIDATING SITE INFORMATION 

valid_site=0
siteValidation () {
	echo "[+] Site Validating..."
	status_code=$(curl -o /dev/null -s -w "%{http_code}\n" $1)
	if echo {300..399} | grep $status_code > /dev/null; then
		echo "[+] Site Validating...[Done]"
		echo "[*] Redirection Found"
		echo "[>] Try to add DNS recodes to /etc/hosts"
		valid_site=1
	elif echo {200..299}| grep $status_code > /dev/null; then
		echo "[+] Site Validating...[Done]"
		echo "[*] Success Response"
		firefox $1 &
		valid_site=1
	else
		echo "[+] Site Validating...[Fail]"
		echo "[!] Something wrong with $IP address, cannot access web"
		valid_site=0
	fi
}

#PATH CREATING AND VALIDATING
#WORK AS A PART OF THE FILESTRUCTURE

path=$PWD
OA=true
pathInput () {
	while $OA; do
		read -p "[?] Enter valid path (or leave it empty for defult path) : " path
		if [[ "${path}" != '' ]]; then
			if [[ -d "${path}" ]]; then
				echo "[*] Given path is found"
				path=$path
				OA=false
			else
				echo "[*] Given path is not found"
				yes_req_arry=('yes' 'Yes' 'y'  'Y' 'YES')
				no_req_arry=('no' 'No' 'n' 'N' 'NO')
				read -p "[?] Do you want to creat that path[yes/no]" user_req
				if (echo $yes_req_arry | grep $user_req &> /dev/null); then
					echo "[*] Path creating..."
					mkdir -p ${path}
					echo "[*] Path was created"
					path=$path
					OA=false				
				elif (echo $no_req_arry | grep $user_req &> /dev/null); then
					continue			
				else
					echo "[!] Invalid request"
					continue
				fi
			fi
		else
			echo "[*] Continuing with path of ($PWD)"
			path=$PWD
			OA=false
		fi
	done
}

#FUNTION WORK AS A PART OF THE FILESTRUCTURE 
#CREATE AND VALIDATE PLATFORM NAME IF THERE ANY

OB=true
platformInput () {
	while $OB; do
		read -p "[?] Enter platform name (or leave it empty for default): " platform
		if [[ "${platform}" != '' ]]; then
			if (echo $platform | grep '/\|~\| ' &> /dev/null); then
				echo "[!] Invalid characters are included('/','~', no space)"
				continue
			else
				if [[ -d "${path}/${platform}" ]]; then
					echo "[*] Platform $platform found"
					path="${path}/${platform}"
					OB=false
				else
					echo "[*] Adding platform to $path"
					cd $path
					mkdir $platform
					path="${path}/${platform}"
					OB=false
				fi
			fi
		else
			echo "[*] No platform is given"
			path=$path
			OB=false
		fi
	done
}

#FILESTRUCTURE -> INTERGATING USER INPUT TO CREATE FILE STRUCTURE
final_path=''
file_structure=0
fileStructure () {
	echo "[+] File creating..."
	pathInput
	platformInput
	if [[ -d "${path}/${name}" ]]; then
		echo "[!] Given name ($name) is already there"
		echo "[+] File creating...[Fail]"
		file_structure=0
	else
		cd $path
		mkdir $name
		final_path="${path}/${name}"	
		echo "[+] File creating...[Done]"
		file_structure=1
	fi
}

#RECON
#RECON IS UNDER MAINTAIN
#FEW TOOL UTILITIES NEED TO BE BUILT USING PYTHON

OC=true
recon () {
	echo "[+] Footprinting..."
	while $OC; do
		read -p "[?] Do you want to do any initial enumarations (optional) (y/n): " enumarate
		if [[ "${enumarate}" != '' ]]; then
			if [[ "${enumarate}" == "y" ]]; then
				nmap -A $1 -v -oN $final_path/nmap_result
				nmap -p- $1 -oN $final_path/nmap_result -append-output
				dig -x $1 > $final_path/dig_result
				dig -x any $1 >> $final_path/dig_result
				if (echo {200..299}| grep $status_code > /dev/null); then
					dirb $1 $wordlist -X > $final_path/dirb_result
				fi
				echo "[*] Enumataion is done"
				echo "[+] Footprinting...[Done]"
				OC=false
			elif [[ "${enumarate}" == "n" ]]; then
				echo "[+] Footprinting...[Done]"
				OC=false
			else
				echo "[!] Invalid request"
				continue
			fi
		else
			echo "[+] Footprinting...[Done]"
			OC=false
		fi
	done
	OK=false
}

#MAIN

echo "[------------CTFstarter-----------]"
while $OK; do
	inputValidation 
	if (($input_validation)); then
		isPinging $IP
		if (($ping_checking)); then
			siteValidation $IP
			if (($valid_site)); then
				fileStructure
				if (($file_structure)); then
					recon $IP
				else
					OK=false
				fi
			else
				OK=false
			fi
		else
			OK=false
		fi
	else
		OK=false
	fi
done
echo "[----------------Bye---------------]"