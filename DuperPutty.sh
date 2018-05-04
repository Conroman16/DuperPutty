#!/bin/bash
# A "superputty" like shell script using tmux/byobu
# Based on http://linuxpixies.blogspot.jp/2011/06/tmux-copy-mode-and-how-to-control.html
echo

username=""
hosts=""
dns_suffix=""
def_sessionname="$(date +%d%h%H%M%S)"
sessionname=$def_sessionname
_params_invalid=false
_deps_invalid=false
OPTIND=1 # Ensure we're starting from a known index

print_help(){
# Prints the help menu
	echo   "EXAMPLE 1: ./DuperPutty.sh USERNAME 'HOST ROSTER' [-s SESSIONNAME] [-d DNSSUFFIX]"
	printf "EXAMPLE 2: ./DuperPutty.sh -u USERNAME -i PATH_TO_HOST_ROSTER_FILE [-s SESSIONNAME] [-d DNSSUFFIX]\n\n"
	echo   "OPTIONS:"
	echo   "    u   User name"
	echo   "    i   Input file containing hostnames"
	echo   "    d   DNS suffix to append to each hostname"
	echo   "    s   Session name [defaults to current date/time (e.g. $def_sessionname)]"
	printf "    h   Print this help menu\n\n"
	echo   "HELPFUL HINTS:"
	echo   "    F3 and F4 to move back and forth between sessions"
	echo   "    CTL+F9 opens small command window to send to each session, hit CTL+C to cancel out"
	printf "    CTL+B, ] to enter scroll mode if text has gone past scroll back, hit CTL+C to cancel out\n\n"
}
read_hosts(){
# Reads contents of the host roster file
	filepath="$1"
	bad_separator_regex='\r?\n|\ +'
	good_separator=' '
	cat "$filepath" | tr "$bad_separator_regex" "$good_separator"
}
ckdependencies(){
# Checks that we have the necessary dependencies available for use
    tmuxrc=`which tmux | wc -l`
    byoburc=`which byobu | wc -l`

    if [ $tmuxrc = "0" ]; then
        echo "tmux does not seem to be installed"
        _deps_invalid=true
    fi
    if [ $byoburc = "0" ]; then
        echo "byobu does not seem to be installed"
        _deps_invalid=true
    fi
}
startbyobu(){
# Fires up byobu and opens a window for each host
	printf "Starting sessions"
	byobu new-session -d -s $sessionname
	for i in $hosts; do
		printf '.' # Print a dot for each host as it's being processed
		if [ -n "$dns_suffix" ]; then
			_hname="$i.$dns_suffix"
		else
			_hname="$i"
		fi
		byobu new-window -t $sessionname "ssh -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=50 $username@$_hname"
		byobu select-layout tiled
	done
	byobu select-window -t 0
	byobu send-keys exit ENTER
	byobu attach -t $sessionname
}
parse_args(){
# Parses and interprets script args

	# Handle options specified without flags
	if [[ -n "$1" && ! "$1" =~ ^- ]]; then
		username="$1"
		OPTIND=$((OPTIND + 1))

		# Only parse out second arg if first one was specified without a flag
		if [[ -n "$2" && ! "$2" =~ ^- ]]; then
			hosts="$2"
			OPTIND=$((OPTIND + 1))
		fi
	fi

	# Handle options specified with flags
	while getopts ":hs:u:i:d:" opt; do
		case ${opt} in
			h ) # Help
				print_help
				exit 0
			;;
			i ) # Input file
				if [ -z "$OPTARG" ]; then
					echo "Hosts file path was not specified"
					exit 0
				else
					hosts=$(read_hosts $OPTARG)
				fi
			;;
			d ) # DNS suffix
				dns_suffix=$OPTARG
			;;
			s ) # Session name
				sessionname=$OPTARG
			;;
			u ) # Username
				username=$OPTARG
			;;
			\? ) # Default case
				print_help
				exit 0
			;;
		esac
	done
}
validate_params(){
# Validates parameters to prevent trouble later
	if [ -z "$username" ]; then
		echo "No username was specified"
		_params_invalid=true
	fi
	if [ -z "$hosts" ]; then
		echo "No hosts were specified"
		_params_invalid=true
	fi
}

# Ensure we have the necessary dependencies installed
ckdependencies
if [ "$_deps_invalid" = true ]; then
	echo
	print_help
	exit 0
fi

# Parse argmuents and validate them
parse_args "$@"
validate_params
if [ "$_params_invalid" = true ]; then
	echo
	print_help
	exit 0
fi

# If we got this far, we're valid and we can start byobu
startbyobu
