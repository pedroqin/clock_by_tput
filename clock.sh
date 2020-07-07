#!/bin/bash
###############################################
# Filename    :   clock.sh
# Author      :   PedroQin
# Email       :   pedro.hq.qin@mail.foxconn.com
# Date        :   2020-07-06 08:20:53
# Description :   Display a clock in a terminal
# Version     :   1.0.0
###############################################

whereami=`cd $(dirname $0);pwd`
Ascii_Signature_dir="$whereami/Ascii_Signature/"
Ascii_Signature="$Ascii_Signature_dir/ascii_signature.sh -n -s "
# source dictionary
. $Ascii_Signature_dir/font/doom
#. $Ascii_Signature_dir/font/smpoison

# we may need assigned length space, we can do this by using "for", but need more time than ${space_placeholder:0:$length}
space_placeholder="                              "
second_bar="###########################################################"
# save the last display 's max length , for overwriting all char last time by using space if last time 's max len > this time'
last_len=0

# for first time diplay sencond bar
start_flag=0
# save WINCH Signal
IF_WINCH=0

# refresh rate, increase it to reduce the cpu loading, from 0.1 to 1
refresh_rate=0.1

# Calculate the size of the terminal
function terminal_size()
{ 
    terminal_cols="$(tput cols)"
    terminal_rows="$(tput lines)"
}

# calculate the size of our output
function ASCII_Art_size() 
{
    ASCII_Art_cols=0
    ASCII_Art_rows=0

    local time_simple=`$Ascii_Signature  "12:34 PM"`
    local line=

    ASCII_Art_rows=`echo "$time_simple"|wc -l`
    for ((i=1;i<=ASCII_Art_rows;i++)); do
        line=`echo -n "$time_simple" |sed -n "$i"p`
        [[ ${#line} -gt $ASCII_Art_cols ]] && ASCII_Art_cols=${#line}
    done
}

function display_clock()
{
    local row=$clock_row
    
    local local_time=`$Ascii_Signature "$(date +'%I:%M %p')"`
    local height=`echo "$local_time"|wc -l`
    local max_len=0
    for ((i=1;i<=height;i++)); do
        tput cup $row $clock_col
        line=`echo -n "$local_time" |sed -n "$i"p`
        line_len="${#line}"
        [ "$max_len" -lt "${line_len}" ] && max_len=$line_len
        echo -n "$line"
        [ "$last_len" -gt "$line_len" ] && echo -n "${space_placeholder:0:$[ $last_len - $line_len ]}"
        ((++row))
    done
    last_len=$max_len
}

function init_clock()
{
    echo -n ${BG_BLUE}${FG_WHITE}

    # In case the terminal cannot paint the screen with a background
    # color (tmux has this problem), create a screen-size string of 
    # spaces so we can paint the screen the hard way.

    blank_screen=
    for ((i=0; i < (terminal_cols * terminal_rows); ++i)); do
        blank_screen="${blank_screen} "
    done

    # Set the background and draw the clock
    
    if tput bce; then # Paint the screen the easy way if bce is supported
        clear
    else # Do it the hard way
        tput home
        echo -n "$blank_screen"
    fi
}

function display()
{
    # Calculate sizes and positions
    terminal_size
    clock_row=$(((terminal_rows - ASCII_Art_rows) / 2))
    clock_col=$(((terminal_cols - ASCII_Art_cols) / 2))
    progress_row=$((clock_row + ASCII_Art_rows + 1))
    progress_col=$(((terminal_cols - 60) / 2))

    # Set the foreground and background colors and go!
    init_clock

    while true; do
    
        tput cup $clock_row $clock_col
        display_clock
        
        # Draw a black progress bar then fill it in white
        tput cup $progress_row $progress_col
        echo -n ${FG_BLACK}
        echo -n "$second_bar"

        tput cup $progress_row $progress_col
        echo -n ${FG_WHITE}
        # only run this in the begin, date +%S may be regarded as octal(like 05,06... 09 is wrong ), the bc translate 06 to 6,09 to 9
        [ $start_flag -eq 0 ] && echo -n "${second_bar:0:`date +%S|bc`}" && let start_flag++ 

        # Advance the progress bar every second until a minute is used up
        #for ((i = $(date +%S|bc); i < 60; i++)); do
        #    echo -n "#"
        #    sleep 1
        #    [ $IF_WINCH -ne 0 ] && return
        #done
        while true;do
            i=$(date +%S|bc)
            [ -z "$ii" ] && ii=$i
            [ $i -gt $ii ] && echo -n "#"
            [ $i -lt $ii ] && unset ii && break
            sleep $refresh_rate
            ii=$i
            [ $IF_WINCH -ne 0 ] && return
        done
    done 
}

# Set a trap to restore terminal on Ctrl-c (exit).
# Reset character attributes, make cursor visible, and restore
# previous screen contents (if possible).

trap 'tput sgr0; tput cnorm; tput rmcup || clear; exit 0' SIGINT
trap 'IF_WINCH=1' WINCH

BG_BLUE="$(tput setab 4)"
FG_BLACK="$(tput setaf 0)"
FG_WHITE="$(tput setaf 7)"

# Save screen contents and make cursor invisible
tput smcup; tput civis

# Calculate sizes
ASCII_Art_size
while true; do
    start_flag=0
    IF_WINCH=0
    display
done
