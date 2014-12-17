# Biblioteca de funciones de uso general.
#
# Copyright (C) 2007 Jorge Fuertes (queru@queru.org)
#
# Este programa es software libre: usted puede redistribuirlo y/o modificarlo 
# bajo los términos de la Licencia Pública General GNU publicada 
# por la Fundación para el Software Libre, ya sea la versión 3 
# de la Licencia, o (a su elección) cualquier versión posterior.
#
# Este programa se distribuye con la esperanza de que sea útil, pero 
# SIN GARANTÍA ALGUNA; ni siquiera la garantía implícita 
# MERCANTIL o de APTITUD PARA UN PROPÓSITO DETERMINADO. 
# Consulte los detalles de la Licencia Pública General GNU para obtener 
# una información más detallada.
#
# Debería haber recibido una copia de la Licencia Pública General GNU 
# junto a este programa. 
# En caso contrario, consulte <http://www.gnu.org/licenses/>.

# RESUMEN DE FUNCIONES:
# titulo, ok, pregunta, preguntaobg, haciendo, informa, finalizado,
# query, sql, sino, errorgrave, aviso.

# RELEASE: 1

# Configuración de colores:
MYDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $MYDIR/colors.inc.sh

# titulo <texto>
# Escribe un título en pantalla, para que todos los programas
# tengan un aspecto común.
function titulo {
	echo -e "\n$(text_color white)---=[$(text_color cyan)${1}$(text_color white)]=---$(text_color normal)"
}

# ok <errorlevel>
# Para usar después de un 'haciendo', cierra la línea con OK o FALLO
# dependiendo del errorlevel pasado. Normalmente 'ok $?'.
function ok {
	if [ $1 -eq 0 ]
	then
		echo -e "$(text_color green)OK$(text_color normal)"
	else
		echo -e "$(text_color red)FALLO$(text_color normal) (Cod.${1})"
	fi
}

# pregunta <texto> <var_sin_dolar> [por defecto]
# Hace una pregunta al usuario, poniéndo el resultado en la variable
# del segundo argumento y poniéndo el tercer argumento como respuesta
# si el usuario responde en blanco.
function pregunta {
	RESPUESTA=""
	echo -e "$(text_color green)>$(text_color white)${1}$(text_color normal) (${3}): \c"
	read RESPUESTA
	if [ -z "$RESPUESTA" ]
	then
		RESPUESTA=$3
	fi	
	eval "$2=\"$RESPUESTA\""
}

# preguntaobg <texto> <var_sin_dolar> [por defecto]
# Igual que la anterior, pero una respuesta es obligatoria
# si no se pasa valor por defecto.
function preguntaobg {
	RESPUESTA=""
	while [ -z "$RESPUESTA" ]
	do
		echo -e "$(text_color green)>$(text_color white)${1}$(text_color normal) (${3})(*): \c"
		read RESPUESTA
		if [ -z "$RESPUESTA" ]
		then
			RESPUESTA=$3
		fi	
	done
	eval "$2=\"$RESPUESTA\""
}
	
# haciendo <texto>
# Para iniciar una acción informando al usuario.
# Al terminar dicha acción se deberá usar 'ok $?'.
function haciendo {
	echo -e "  $(text_color yellow)- $(text_color white)${1}$(text_color normal)...\c"
}

# informa <texto>
# Da una información al usuario.
function informa {
	echo -e "$(text_color yellow)+$(text_color normal) ${1}$(text_color normal)"
}

# finalizado <errorlevel>
# Finaliza el programa saliendo con el errorlevel que se le diga.
function finalizado {
	echo -e "\n*** $(text_color white)Finalizado$(text_color normal) ***"
	exit $1
}

# query <texto> <sql>
# Lanza una consulta a MySQL y muestra el resultado.
function query {
	haciendo $1
	RES=$(echo $2 | mysql|tr "\n" "|")
	ok $?
	if [ -z "$RES" ]
	then
		informa "Sin resultado."
		return 1
	else
		informa "Resultado:"
		echo $RES|tr "|" "\n"	
	fi
}

# sql <texto> <sql>
# Envía SQL sin esperar respuesta:
function sql {
	haciendo $1
	echo $2 | mysql
	ok $?
}

# sino <texto>
# Hace una pregunta al usuario pero sólo le permite
# responder 's' o 'n'. Devuelve el estado 0 o 1.
function sino {
	echo -e "$(text_color green)>$(text_color white)${1}$(text_color normal) (s/N): \c"
	read -n1 RESPUESTA
	echo
	if [[ "$RESPUESTA" == "s" || "$RESPUESTA" == "S" ]]
	then
		return 0
	else
		return 1
	fi
}

# errorgrave <texto>
# Muestra un error grave y sale del programa.
function errorgrave {
	echo -e "\n$(text_color red)> ERROR$(text_color normal): ${1}\n"
	exit 1
}

# aviso <texto>
# Muestra un aviso por pantalla.
function aviso {
	echo -e "\n$(text_color yellow)> $(text_color red)AVISO$(text_color normal): ${1}\n"
}

