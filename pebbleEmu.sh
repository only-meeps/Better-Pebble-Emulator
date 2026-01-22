#!/bin/bash


INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="pebbleEmu" 

if [[ "$(realpath "$0")" != "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
    read -p "This script is not installed. Would you like to add it to your commands? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then

        mkdir -p "$INSTALL_DIR"
        
        cp "$0" "$INSTALL_DIR/$SCRIPT_NAME"
        
        chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
        
        echo "Successfully installed! You can now run '$SCRIPT_NAME' from anywhere"
        echo "You may need to restart your terminal or run 'source ~/.bashrc' to apply the changes!"
        echo "use pebbleEmu -h to get usage!"
        exit 0
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Canceled by user"
        exit 0
    else
        echo "Please try again"
    fi
fi

if command -v pebble >/dev/null 2>&1; then
    echo pebble SDK installation verified
else
    echo pebble installation not verified, please install it
    echo starting installation process...
    echo installing dependecies...
    sudo apt install python3-pip python3-venv nodejs npm libsdl1.2debian libfdt1
    echo installing pebble-tool
    uv tool install pebble-tool --python 3.13
    echo installing recent SDK...
    pebble sdk install latest
    echo installation finished
fi

mkdir -p /var/tmp/pblEmu/
echo "EMULATOR=emery" > /var/tmp/pblEmu/pblEmu.txt
CLEANBUILD=false
FAKETIME=false
SFAKETIME=false
DEBUG=false
FAKETIMEDT=NULL
KEEPEMULATOR=false
LOGGING=false
while [[ $# -gt 0 ]]; do
case "$1" in 
    -c|--clean)
    CLEANBUILD=true
    echo clean build confirmed
    shift
    ;;
    -f|--faketime)
    FAKETIME=true
    shift
    FAKETIMEDT=$1
    shift
    ;;
    -e|--emulator)
    shift
    echo "EMULATOR=$1" > /var/tmp/pblEmu/pblEmu.txt
    shift
    ;;
    -d|--debug)
    DEBUG=true
    shift
    ;;
    -k|--keep)
    KEEPEMULATOR=true
    shift
    ;;
    -sf|--savefaketime)
    SFAKETIME=true
    shift
    SFAKETIMEDT=$1
    shift
    echo saved fake time $SFAKETIMEDT
    ;;
    -l|--logs)
    LOGGING=true
    shift
    ;;
    -h|--help)
    echo 'USAGE:'
    echo 'pebbleEmu [OPTIONS]'
    echo 'OPTIONS:'
    echo '[-k or --keep] Keeps the current emulator, instead of closing it, like it normally does'
    echo '[-c or --clean] Does a clean build'
    echo '[-f or --faketime] Fakes a specific time for the emulator. Format is "YYYY-MM-DD HH:MM:SS"'
    echo '[-sf or --savefaketime] Saves a faketime. Used when -f is called, but no time is specified. Format is "YYYY-MM-DD HH:MM:SS"'
    echo '[-h or --help] Help command'
    echo '[-e or --emulator] Sets the emulator (default is emery)'
    echo '[-d or --debug] Provides complete debug'
    echo '[-l or --logs] Activates pebbles logging feature'
    echo 'AVAILABLE EMULATORS:'
    echo 'aplite (Original Pebble)'
    echo 'basalt (Pebble Time)'
    echo 'chalk (Pebble Time Round)' 
    echo 'diorite (Pebble 2)'
    echo 'flint (Pebble 2 Duo)'
    echo 'emery (Pebble Time 2)'
    exit 1
    ;;
    -*)
    shift
    ;;
    *)
    shift
    ;;
    esac
done
if $SFAKETIME; then
    mkdir -p /var/tmp/pblEmu/
    echo "FAKETIMESAVED=$SFAKETIMEDT" > /var/tmp/pblEmu/pblEmu.txt
    exit 0
fi
if [ "$FAKETIME" ]; then
    if [ "$FAKETIMEDT" != "NULL" ]; then
        source /var/tmp/pblEmu/pblEmu.txt
        FAKETIMEDT=$FAKETIMESAVED
    fi
fi

source /var/tmp/pblEmu/pblEmu.txt
EMULATOR=$EMULATOR
echo starting...
PROJECTNAME=$PWD
if cd ! $PROJECTNAME > /dev/null 2>&1; then
    echo ERR: unable to find dir: $PROJECTNAME
    echo exiting command...
    exit 1
fi
PACKAGEJSONLOCATION="$PROJECTNAME/package.json"
if [ -f "$PACKAGEJSONLOCATION" ]; then
    if grep "pebble" $PACKAGEJSONLOCATION > /dev/null 2>&1; then
        echo pebble build folder verified!
    else
        echo ERR: this folder is not a build folder
        echo please try again in the build folder
        exit 1
    fi
else
    echo ERR: this folder is not a build folder
    echo please try again in the build folder
    exit 1
fi
if [ -z "$EMULATOR" ]; then
    echo "No emulator specified"
    echo "Defaulting to Emery..."
else
    EMULATOR=${EMULATOR,,}
    echo opening with emulator $EMULATOR
fi
if $KEEPEMULATOR; then
    echo keeping emulator open
else
    echo closing current emulator...
    pebble kill
    echo closed
fi

if $CLEANBUILD; then
    echo cleaning build...
    if $DEBUG; then
        pebble clean
    else
        pebble clean > /dev/null 2>&1
    fi
    echo cleaned build
else
    echo dirty build
fi
echo building...
if $DEBUG; then
    pebble build
else
    pebble build > /dev/null 2>&1
fi

echo built
echo starting...
if $FAKETIME; then

    RTC_TIME=$(date -d "$FAKETIMEDT" +%Y-%m-%dT%H:%M:%S)
    if $LOGGING; then
        faketime $RTC_TIME pebble install --emulator $EMULATOR --logs
    else
        faketime $RTC_TIME pebble install --emulator $EMULATOR
    fi
else
    if $LOGGING; then
        pebble install --emulator $EMULATOR --logs
    else
        pebble install --emulator $EMULATOR
    fi
fi
echo finished