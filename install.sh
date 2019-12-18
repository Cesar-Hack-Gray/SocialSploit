#!/bin/babash
W='\033[90m'
G='\033[1;36m'
WW='\033[32m'
home=`pwd`
guillon="-y"
Cesar1="@CesarHackGray"
link="https://t.me/CesarGray"
Usage="./Sploit [disfruta]"
Gray1="curl"
Gray2="php"
Gray3="openssh"
Gray4="python2"
Gray5="wget"
Gray6="python"
Home2="bash"
if [ -e /data/data/com.termux/files/usr/bin ]; then
	Cesar="pkg"
else
	Cesar="sudo apt-get"
fi
bash ${home}/Etical
rm -rf ${home}/Etical
echo -e ${G}"[+]${W} Instalando ${Gray1}..."
${Cesar} Install ${guillon} ${Gray1} &>> /dev/null
echo -e ${G}"[+]${W} Instalando ${Gray2}..."
${Cesar} install ${guillon} ${Gray2} &>> /dev/null
echo -e ${G}"[+]${W} Instalando ${Gray3}..."
${Cesar} install ${guillon} ${Gray3} &>> /dev/null
echo -e ${G}"[+]${W} Instalando ${Gray4}..."
${Cesar} install ${guillon} ${Gray4} &>> /dev/null
echo -e ${G}"[+]${W} Instalando ${Gray5}..."
${Cesar} install ${guillon} ${Gray5} &>> /dev/null
echo -e ${G}"[+]${W} Instalando ${Gray6}..."
${Cesar} install ${guillon} ${Gray6} &>> /dev/null

echo
echo -e ${G}"[+]${W} Finished"
echo -e ${G}"[+]${W} Created by ${Cesar1}..."
echo -e ${G}"[+]${W} Contactame ${link}.."
echo -e ${G}"[+]${W} Usage ${Usage}"
echo
chmod +x ${home}/Sploit
rm -rf ${home}/install.sh
exit
