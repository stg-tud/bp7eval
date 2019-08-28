#!/bin/bash

while read -r line; do 
if [[ $line == *"INFO:CONSOLE"* ]]; then
    msg=$(echo $line | cut -d \" -f2)
    echo  "$msg"

    if [[ $msg == "end"* ]]; then
        exit
    fi
fi

done < <("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --enable-logging --v=1 --user-data-dir=/tmp/gc1 --remote-debugging-port=9222 http://127.0.0.1:8080/ 2>&1)