#!/bin/bash

print_usage()
{
    echo "cicd_helper.sh [options]"
    echo "  options:"
    echo "  -h: print help"
    echo "  -d: dry run: print what will be done"
    echo "  -s: use 'sudo' when it is needed"
    echo "  -w: working path to mount at /data/"
    echo "  -t: tool path to mount at /pkg/"
    echo "  -n: number of user ( 1->number )"
    echo "NOTE"
    echo "  This container base on ghcr.io/cavli-wireless/sdx35/owrt:latest"
    echo "  Create user which refer from caller env ( result of whoami )"
    echo "  Mount and setup env to build"
    echo "  USER MUST PREPARE TOOLS BUILD"
}

# Parse command line arguments
while getopts "hdsrw:t:n:k:" flag; do
  case $flag in
    d) DRYRUNCMD="echo";;
    s) SUDO="sudo";;
    r) RESET=true;;
    w) CICD_ROOT=$OPTARG;;
    t) TOOL_PATH=$OPTARG;;
    n) NUMBER=$OPTARG;;
    k) KEY=$OPTARG;;
    *) print_usage; exit 1;;
  esac
done

shift $(( $OPTIND - 1 ))

if [ -z $KEY ] || [ -z $CICD_ROOT ] || [ -z $TOOL_PATH ]; then
    echo "Please give me, WORKPATH and TOOLPATH"
    exit 1
fi

# Loop from 0 to n-1
for (( i=0; i<$NUMBER; i++ ))
do
  bash ./cicd_helper.sh -w $CICD_ROOT -t $TOOL_PATH -k $KEY -n $i
done
