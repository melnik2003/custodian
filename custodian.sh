#!/bin/bash
# ------------------------------------------------------------------
# [Мельников М.А.] "Custodian" - script-managment script
# 
# This is a tool to help one adding execute permissions on
# scripts and making links in the bin directory
# ------------------------------------------------------------------

# --- Global -------------------------------------------------------
VERSION=0.2.0
SUBJECT=$0

PATH_TO_LINKS="/usr/local/bin/"

# Choose logging level (1 - errors, 2 - warnings, 3 - info, 4 - debug)
LOGGING_LEVEL=4
# ------------------------------------------------------------------

# --- Notes --------------------------------------------------------
# Figure out how to make second option parsing
# ------------------------------------------------------------------

# --- Utils --------------------------------------------------------
show_help_en() {
	echo "Usage: . $0 [-param <value>]"
	echo ""
	echo "Main params:"
	echo "-m <path> <link_name>		Make a link to the script"
	echo "							Will prompt to create one if it doesn't exist"
	echo ""
	echo "-r <link_name>			Remove the link"
	echo ""
	echo "-R <link_name>			Remove the link and the script"
	echo ""
	echo "-h						Print this help message"
	echo ""
	echo "-v						Print the script version"
	echo ""
	echo "Additional params:"
	echo "-l <level>				Choose logging level (1 - errors, 2 - warnings, 3 - info, 4 - debug)"
	echo ""
	echo "-y						Skip all warnings"
}

show_logs() {
    local error_prefix=$'\e[31m[ERROR]\e[0m'
    local warning_prefix=$'\e[33m[WARNING]\e[0m'
    local info_prefix=$'\e[32m[INFO]\e[0m'
    local debug_prefix=$'\e[96m[DEBUG]\e[0m'

    local msg_log_lvl=$1
    local msg="$2"
    local nmode=$3

    case $msg_log_lvl in
        "1")
            if (( LOGGING_LEVEL >= msg_log_lvl )); then
                echo "${error_prefix} ${msg}"
            fi
            exit 1
            ;;
        "2")
            if (( LOGGING_LEVEL >= msg_log_lvl )); then
                echo "${warning_prefix} ${msg}"
                if (( YES == 0 )); then
                    read -p "${warning_prefix} Do you wish to continue? (y/n): " answer
                    if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
                        echo "${warning_prefix} You've been warned..."
                        return
                    else
                        show_logs 3 "Closing script..."
                        exit 0
                    fi
                fi
            fi
            ;;
        "3")
            if (( LOGGING_LEVEL >= msg_log_lvl )); then
                if (( nmode == 1 )); then
                    echo -n "${info_prefix} ${msg}"
                else
                    echo "${info_prefix} ${msg}"
                fi
            fi
            ;;
        "4")
            if (( LOGGING_LEVEL >= msg_log_lvl )); then
                echo "${debug_prefix} ${msg}"
            fi
            ;;
    esac
}

validate_path() {
    local path="$1"
	
	if [ ! -e "$path" ]; then
		show_logs 1 "There's no such path: ${path}"
	fi
}

validate_dir() {
    local path="$1"
	
	if [ ! -d "$path" ] ; then
		show_logs 1 "There's no such directory: ${path}"
	fi
}

validate_file() {
    local path="$1"
	
	if [ ! -f $path ] ; then
		show_logs 1 "There's no such file: ${path}"
	fi
}
# ------------------------------------------------------------------

# --- Params processing --------------------------------------------
if [ $# == 0 ] ; then
	show_help_en
	exit 1
fi

main_params=("m" "r" "R" "h" "v")

main_param=""

PATH_TO_SCRIPT=""
PATH_TO_LINK=""
YES=0

while getopts ":m:r:R:hvl:y" param
do
	if [[ " ${main_params[@]} " =~ "$param" ]]; then
		if [ "$main_param" == "" ]; then
			main_param="$param"
		else
			show_logs 1 "Choose the only one main parameter"
		fi
	fi

	case "$param" in
		"m")
			PATH_TO_SCRIPT="$OPTARG"
			if [ ! -f "$PATH_TO_SCRIPT" ]; then
				show_logs 2 "Script ${PATH_TO_SCRIPT} doesn't exist, going to create it now"
				touch "$PATH_TO_SCRIPT"
			fi
			### Second argument
			PATH_TO_LINK="${PATH_TO_LINKS}${OPTARG}"
			;;

		"r")
			PATH_TO_LINK="${PATH_TO_LINKS}${OPTARG}"
			validate_file "$PATH_TO_LINK"
			;;

		"R")
			PATH_TO_LINK="${PATH_TO_LINKS}${OPTARG}"
			validate_file "$PATH_TO_LINK"
			PATH_TO_SCRIPT=$(readlink -f "$PATH_TO_LINK")
			validate_file "$PATH_TO_SCRIPT"
			;;


		"h") ;;
		"v") ;;

		"l")
			if [[ "$OPTARG" =~ ^-?[0-9]+$ ]]; then
				if (( OPTARG >= 1 && OPTARG <= 4 )); then
					LOGGING_LEVEL=$OPTARG
					continue
				fi
			fi
			show_logs 1 "Wrong argument for -l option: $OPTARG, use 1-4 instead"
			;;
		"y")
			YES=1
			;;

		"?")
			show_logs 1 "Unknown parameter $OPTARG"
			;;
		":")
			show_logs 1 "Need an argument for $OPTARG"
			;;
		*)
			show_logs 1 "Uknown error while parsing parameters"
			;;
	esac
done

shift $(($OPTIND - 1))

if [ "$main_param" == "" ]; then
	show_logs 1 "Choose the main param"
fi
show_logs 4 "Parameters parsed. The main param: ${main_param}"
# -----------------------------------------------------------------

# --- Locks -------------------------------------------------------
LOCK_FILE=/tmp/$SUBJECT.lock
if [ -f "$LOCK_FILE" ]; then
	show_logs 1 "The script is running right now. If not, delete the lock file: ${$LOCK_FILE}"
fi

trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE
# -----------------------------------------------------------------

# --- Body --------------------------------------------------------
case "$main_param" in
	"m")
		chmod +x "$PATH_TO_SCRIPT"
		show_logs 4 "Added execute permission to the script:${PATH_TO_SCRIPT}"

		ln -s "$PATH_TO_SCRIPT" "$PATH_TO_LINK"
		show_logs 4 "Created link: ${PATH_TO_LINK}"
		
		show_logs 3 "Success. Use \"${LINK_NAME}\" for your script"
		;;

	"r")
		rm -rf $PATH_TO_LINK
		show_logs 4 "Removed link: ${PATH_TO_LINK}"

		show_logs 3 "Success"
		;;

	"R")
		rm -rf $PATH_TO_LINK
		show_logs 4 "Removed link: ${PATH_TO_LINK}"
		
		rm -rf $PATH_TO_SCRIPT
		show_logs 4 "Removed script: ${PATH_TO_LINK}"

		show_logs 3 "Success"
		;;

	"h")
		show_help_en
		;;

	"v")
		echo "Version: ${VERSION}"
		;;
esac

exit 0
# -----------------------------------------------------------------
