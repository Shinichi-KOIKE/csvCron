#!/bin/bash
set -f

#files
CRONFILE="${RANDOM}${RANDOM}${RANDOM}"
CRONTMP=""
CRONOUTPUT=""

#parameters
MON="mon"
DOM="dom"
DOW="dow"
OUR="our"
MIN="min"

#constants
LOMON="1"
HIMON="12"
LODOM="1"
HIDOM="31"
LODOW="0"
HIDOW="6"
LOOUR="0"
HIOUR="23"
LOMIN="0"
HIMIN="59"

#option flags
f_mon="0"
f_dom="0"
f_dow="0"
f_our="0"
f_min="0"

#parsed results
MON_C=""
DOM_C=""
DOW_C=""
OUR_C=""
MIN_C=""
COM_C=""

function parseParam()
{
	RESULT=""
	case ${2} in
		${MON}) LO=${LOMON}; HI=${HIMON};;
		${DOM}) LO=${LODOM}; HI=${HIDOM};;
		${DOW}) LO=${LODOW}; HI=${HIDOW};;
		${MIN}) LO=${LOMIN}; HI=${HIMIN};;
		${OUR}) LO=${LOOUR}; HI=${HIOUR};;
		*) echo "invalid type"; exit 99;;
	esac

	for PARAM in ${1//,/ }
	do
		if [ ${PARAM} == "*" ]; then
			RESULT=`seq -s " " ${LO} ${HI}`
		elif [[ ${PARAM} =~ /[0-9]* ]]; then
			RANGE=`echo ${PARAM} | cut -d/ -f1`
			INTVL=`echo ${PARAM} | cut -d/ -f2`

			if [[ ${RANGE} == "*" ]]; then
				RESULT="${RESULT} `seq -s " " ${LO} ${INTVL} ${HI}`"
			else
				FM=`echo ${RANGE} | cut -d- -f1`
				TO=`echo ${RANGE} | cut -d- -f2`

				RESULT="${RESULT} `seq -s " " ${FM} ${INTVL} ${TO}`"
			fi
		elif [[ ${PARAM} =~ [0-9]*-[0-9]* ]]; then
			FM=`echo ${PARAM} | cut -d- -f1`
			TO=`echo ${PARAM} | cut -d- -f2`

			RESULT="${RESULT} `seq -s " " ${FM} ${TO}`"
		elif [[ ${PARAM} =~ [0-9]* ]]; then
			RESULT="${RESULT} ${PARAM}"
		fi
	done

	case ${2} in
		${MIN}) MIN_C=${RESULT};;
		${OUR}) OUR_C=${RESULT};;
		${DOM}) DOM_C=${RESULT};;
		${MON}) MON_C=${RESULT};;
		${DOW}) DOW_C=${RESULT};;
	esac
}

function displaySchedule()
{
	for MON_F in ${MON_C}
	do
		for DOM_F in ${DOM_C}
		do
			for DOW_F in ${DOW_C}
			do
				for OUR_F in ${OUR_C}
				do
					for MIN_F in ${MIN_C}
					do
						echo "${MON_F},${DOM_F},${DOW_F},${OUR_F},${MIN_F},${COM_C}" >> ${CRONOUTPUT}
					done
				done
			done
		done
	done
}

function usage()
{
	echo "
Usage: `basename $0`: [-e mon|dom|dow|hour|min] -i cronfile -o outputfile
		-e:exclude parameter
		  Specified parameters with this option will be treated as '*'.
		  This parameter can be specified up to 5 times.
		  mon:month
		  dom:day of month
		  dow:day of week
		  our:hour
		  min:minute
		-i:cronfile
		  cron file to parse
		-o:outputfile
		  csv file to create"
	exit 99
}

if [ $# -lt 4 ]; then
	usage
fi

while getopts 'e:i:o:' OPTION
do
	case $OPTION in
		e)
		case $OPTARG in
			${MON}) f_mon="1";;
			${DOM}) f_dom="1";;
			${DOW}) f_dow="1";;
			${OUR}) f_our="1";;
			${MIN}) f_min="1";;
		esac
		;;
		i) CRONFILE="${OPTARG}";;
		o) CRONOUTPUT="${OPTARG}";;
		*) usage
	esac
done

ls ${CRONFILE} > /dev/null
if [ ${?} -ne 0 ]; then
	echo "no such file"
	exit 99
fi

CRONTMP=${CRONFILE}.tmp

while read LINE
do
	echo ${LINE} | egrep "^#|^$" > /dev/null
	if [ ${?} -ne 0 ]; then
		echo ${LINE} >> ${CRONTMP}
	fi
done < ${CRONFILE}

echo "Month,Day of Month,Day of Week,Hour,Minuit,Command" >> ${CRONOUTPUT}

while read MINS OURS DOMS MONS DOWS COMS
do
	if [ ${f_mon} == "0" ]; then parseParam ${MONS} ${MON}; else MON_C="*"; fi
	if [ ${f_dom} == "0" ]; then parseParam ${DOMS} ${DOM}; else DOM_C="*"; fi
	if [ ${f_dow} == "0" ]; then parseParam ${DOWS} ${DOW}; else DOW_C="*"; fi
	if [ ${f_our} == "0" ]; then parseParam ${OURS} ${OUR}; else OUR_C="*"; fi
	if [ ${f_min} == "0" ]; then parseParam ${MINS} ${MIN}; else MIN_C="*"; fi
	COM_C=${COMS}

	displaySchedule
done < ${CRONTMP}

rm ${CRONTMP}
