# Colores:
NORMAL="\033[0;"
BOLD="\033[1;"

RED=31
GREEN=32
BROWN=33
BLUE=34
MAGENTA=35
CYAN=36
WHITE=37
YELLOW=33

function text_color {
	if [[ "$COLOR" != "false" ]]
	then
		if [[ $2 == "bold" ]]
		then
			PREFIX=$BOLD
		else
			PREFIX=$NORMAL
		fi

		COLORNAME=$(echo $1|tr "[:lower:]" "[:upper:]")
		echo "${PREFIX}${!COLORNAME}m"
	fi
}


function bg_color {
	if [[ "$COLOR" != "false" ]]
	then
		COLORNAME=$(echo $1|tr "[:lower:]" "[:upper:]")
		let "BGVALUE = ${!COLORNAME} + 10"
		echo "${NORMAL}${BGVALUE}m"
	fi
}

