#!/bin/bash
# A "superputty" like shell script using tmux/byobu
# Based on http://linuxpixies.blogspot.jp/2011/06/tmux-copy-mode-and-how-to-control.html

usage(){
    echo
    echo "####################################"
    echo "    WARNING: Options are missing"
    echo "####################################"
    echo 
    echo "EXAMPLE: ./DuperPutty.sh SESSIONNAME USERNAME 'HOST1 HOST2 HOST3'"
    echo "NOTE: Don't forget the ' ' when specifying hosts"
    echo
    echo "####################################"
    echo "          HELPFUL HINTS:"
    echo "####################################"
    echo
    echo "-- F3 and F4 to move back and forth between sessions"
    echo "-- CTL + F9 opens small command window to send to each session, hit CTL+C to cancel out"
    echo "-- CTL+B ] to enter scroll mode if text has gone past scroll back, hit CTL+C to cancel out"
    echo
}
ckdependencies(){
    # GET OS Version first, just support CentOS and Ubuntu for now
    # Query package manager for byobu and tmux
    # Spit out install command if they are missing

    tmuxrc=`which tmux | wc -l`
    byoburc=`which byobu | wc -l`

    if [ $tmuxrc = "0" ]; then 
        echo "tmux does not seem to be installed, please install"
    elif [ $byoburc = "0" ]; then 
        echo "byobu does not seem to be installed, please install"
    else
        startbyobu
    fi
}
startbyobu(){
    printf "\n$HOSTS\n"
    if [ -z "$HOSTS" ]; then
       echo -n "Please provide of list of hosts separated by spaces [ENTER]: "
    fi
    
    byobu new-session -d -s $sessionname 

    for i in $HOSTS; do
        byobu new-window -t $sessionname "ssh -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=50 $username@$i.cdc.nicusa.com"
        byobu select-layout tiled
    done

    byobu select-window -t 0
    byobu send-keys exit ENTER  
    byobu attach -t $sessionname

    BNAME=`basename $0`
}
help_cmd(){
    usage
}

# If we weren't supplied with enough args, print usage info and exit
if  [ $# -lt 1 ]; then
    usage
    exit 0
fi

# Set vars
sessionname=$1
username=$2
HOSTS="$3"

# Check our dependencies and startbyobu if all is well
ckdependencies
