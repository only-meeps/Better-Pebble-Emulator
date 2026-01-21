#!/bin/bash

mkdir -p /var/tmp/pblemu/
echo "EMULATOR=emery" > /var/tmp/pblemu/pblemu.txt
CLEANBUILD=false
FAKETIME=false
DEBUG=false
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
    FAKETIMET=$1
    shift
    echo fake time confirmed $FAKETIMEDT $FAKETIMET
    ;;
    -e|--emulator)
    shift
    echo "EMULATOR=$1" > /var/tmp/pblemu/pblemu.txt
    shift
    ;;
    -d|--debug)
    DEBUG=true
    shift
    ;;
    -h|--help)
    echo 'COMMAND STRUCTURE:'
    echo 'pebble_emu [OPTIONS]'
    echo 'OPTIONS:'
    echo '[-c or --clean] Does a clean build'
    echo '[-f or --faketime] Fakes a specific time for the emulator'
    echo '[-h or --help] Help command'
    echo '[-e or --emulator] Sets the emulator (default is emery)'
    echo '[-d or --debug] Shows the debug logs of all commands'
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
source /var/tmp/pblemu/pblemu.txt
EMULATOR=$EMULATOR
echo starting...
PROJECTNAME=$PWD
echo finding project $PROJECTNAME...
if cd $PROJECTNAME > /dev/null 2>&1; then
    echo found project $PROJECTNAME

else
    echo ERR: unable to find project $PROJECTNAME
    echo exiting command...
    exit 1
fi
if [ -z "$EMULATOR" ]; then
    echo "No emulator specified"
    echo "Defaulting to Emery..."
else
    EMULATOR=${EMULATOR,,}
    echo opening with emulator $EMULATOR
fi
echo closing current emulator...
pebble kill
echo closed
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
    if $DEBUG; then
        pkill -f qemu-system-arm
    else
        pkill -f qemu-system-arm 2>/dev/null
    fi

    RTC_TIME=$(date -d "$FAKETIMEDT $FAKETIMET" +%Y-%m-%dT%H:%M:%S)
    echo "Launching QEMU directly with RTC: $RTC_TIME"
    ~/.pebble-sdk/SDKs/current/sdk-core/pebble/common/qemu/qemu-system-arm \
        -rtc base="$RTC_TIME" \
        -f $EMULATOR & 

    echo "Waiting for hardware boot..."
    sleep 10
    pebble install
else
    pebble install --emulator $EMULATOR
fi
echo finished