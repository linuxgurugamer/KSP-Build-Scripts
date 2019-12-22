#!/bin/bash

# detailed information located here:  https://forum.kerbalspaceprogram.com/index.php?/topic/102909-*/

#  This file sets up a fresh Development mode install of KSP from a specified KSP installation.
#  If CKAN is installed, it will present a list of all installs in CKAN to choose from.

#  Change Log:
#  v2.0  add support for unity 2019.
#  v3.0  Converted to bash shell, tested in Cygwin
#		Now accesses CKAN if installed and specified to get list of installs

#
# This script was written for use on CygWin on Windows
# While untested, setting the variable WINDOWS to false should disable the Windows-specific code
# It also assumes that all the 
#

#
# The script currently is set up for KSP 1.8.  For earlier versions of the game
# you will have to update where the correct version of UNITY for that version of KSP is installed
#

clear

#
# The following lines need to be customized for each environment
#
WINDOWS=true

CKAN_EXE=/d/KerbalInstalls/ckan/ckan.exe
KSP_EXE=ksp_x64_dbg.exe
GAME_DIR=/r/KSP_1.8.1_Career # source game directory
LCL_DIR=/r/dp0              # source directory for Unity debug finish

#
# Specify the desired window size here
#
WIDTH=1600
HEIGHT=1024

#
# The location where the correct version of Unity is installed
#
UNITY="/e/Program Files/Unity524f1"




##### End of customizable lines ############################
#
##### You should not need to change any of the lines below
UNITYDIR="${UNITY}/Editor/Data/PlaybackEngines/windowsstandalonesupport/Variations/win64_development_mono"
WINDOWSPLAYER="${UNITYDIR}"/WindowsPlayer.exe
UNITYPLAYER="${UNITYDIR}"/UnityPlayer.dll
EVENTRUNTIME="${UNITYDIR}"/WinPixEventRuntime.dll

if [ ! -f ${WINDOWSPLAYER} ]; then
	echo -e "\nMissing WindowsPlayer exe:  $WINDOWSPLAYER"
	exit
fi


IFS=$oIFS
KSP_DIR=${LCL_DIR}/kspdev       # destination for the debug install

tmpfile=tmp.$$
oIFS=$IFS
doallsteps=false

#
########### Functions ################
#

function GetKspInstalls
{
	[ "$CKAN_EXE" = "" ] && return
	[ ! -f $CKAN_EXE ] && return


	$CKAN_EXE ksp list > $tmpfile
	cnt=-1
	IFS=
	while read line; do
		if [ $cnt -le 0 ]; then
			echo "    $line"
		else
			printf "%4d " $cnt
			echo $line
			arr[$cnt]=$line
		fi
		cnt=$((cnt+1))
	done < $tmpfile
	rm $tmpfile
	echo -ne "\nEnter number of install to copy, press <return> for default ($GAME_DIR): "
	read n
}

#
# Display a prompt, if supplied and wait for user entry
#
function prompt
{
    echo $1
    [ $doallsteps = false ] && read -p "Press <return> to continue"
}

#
# Do all steps to set up the dev install
#
function DoAll()
{
    doallsteps=true
    backupGame
    removeGame
    createFolder
    copyGame
    copyDebugFiles
    createLinkedFolder
	resetResolution
    finish
}

#
# Make a backup of the current dev build
#
function backupGame
{
    if [ ! -d $KSP_DIR ]; then
        echo "No game directory available to backup"
    else
        prompt "- Backup existing game folder..."
        echo 

        echo     - Backup in progress, please wait...
        #xcopy /E /Y /Q ""${KSP_DIR}"/*.*" ""${KSP_DIR}"_%VERSION%_old/"
        rm -fr "${KSP_DIR}"_${VERSION}_old
        mkdir "${KSP_DIR}"_${VERSION}_old
        cp -a "${KSP_DIR}" "${KSP_DIR}"_${VERSION}_old

        echo     - Backup complete...
        echo
    fi
}

#
# Remove the current dev build
#
function removeGame
{
   if [ ! -d $KSP_DIR ]; then
        echo "No game directory available to remove"
    else
        prompt "     - Removing existing game folder..." pause
        #rmdir /s /q ""${KSP_DIR}""
        rm -fr "${KSP_DIR}"
        echo     - Removal complete...
        echo 
    fi
}

#
# Create new game folder
#
function createFolder
{
    prompt "     - Creating new game folder..." pause
    if [ ! -f ""${KSP_DIR}"" ]; then
        mkdir "${KSP_DIR}"        
        echo     - Game folder created...
    else 
        echo     - Game folder exists.  Skipping...
    fi
    echo
}

#
# Copy the entire game from the $GAME_DIR
#
function copyGame
{
    echo     - Ready to Copy specified KSP Game to local Game folder...
    echo       from: ""${GAME_DIR}"" 
    echo         to: ""${KSP_DIR}""
    prompt ""
    cp -a "${GAME_DIR}"/* "${KSP_DIR}"/
    echo     - Copy complete...
    echo
}

#
# Copy the files needed to setup the install as a debug build
#
function copyDebugFiles
{
    prompt "     - Ready to Copy unity debug files to game folder and set debug mode..."
    
    echo player-connection-debug=1 >> ""${KSP_DIR}"/KSP_x64_Data/boot.config"
    
    cp  "${WINDOWSPLAYER}" "${KSP_DIR}"/ksp_x64_dbg.exe
    cp  "${UNITYPLAYER}" "${KSP_DIR}"
    cp  "${EVENTRUNTIME}" "${KSP_DIR}"


    echo     - Copy complete...
    echo
}

#
# Copy the Game savefiles, not called when doing all
#
function copyGameSaves
{
    prompt "     - Ready to Copy ships, Saves and mods to the new game folder." pause
    #xcopy /E /Y /D ""${KSP_DIR}"_%VERSION%_old/GameData/*.*" ""${KSP_DIR}"/GameData/"
    #xcopy /E /Y /D ""${KSP_DIR}"_%VERSION%_old/ships/*.*" ""${KSP_DIR}"/Ships/"
    #xcopy /E /Y /D ""${KSP_DIR}"_%VERSION%_old/saves/*.*" ""${KSP_DIR}"/saves/"

    cp -a "${KSP_DIR}"_${VERSION}_old/GameData/* "${KSP_DIR}"/GameData/
    if [ -d "${KSP_DIR}"_${VERSION}_old/ships ]; then   
        cp -a "${KSP_DIR}"_${VERSION}_old/ships/* "${KSP_DIR}"/Ships/
    else
        [ ! -d "${KSP_DIR}"/Ships } &&  mkdir "${KSP_DIR}"/Ships 
    fi
    if [ -d "${KSP_DIR}"_${VERSION}_old/saves ]; then
        cp -a "${KSP_DIR}"_${VERSION}_old/saves/* "${KSP_DIR}"/saves/
    else
        [ ! -d "${KSP_DIR}"/saves ] && mkdir "${KSP_DIR}"/saves
    fi


    echo     - Copy complete...
    echo 
}

#
# Create the link needed for debugging
#
function createLinkedFolder
{
    prompt "     - Ready to create the linked folder for debugging..." pause

    #REM cd /d ""${KSP_DIR}""
    #REM @echo     - Curr Dir:  "%cd%"
    #REM @echo     - Game Directory:  ""${KSP_DIR}""...
    #REM @echo: 
    #REM pause

    #rem mklink /J ""${KSP_DIR}""/KSP_x64_Dbg_Data ""${KSP_DIR}""/KSP_x64_Data
    ln -s "${KSP_DIR}"/KSP_x64_Data "${KSP_DIR}"/KSP_x64_Dbg_Data 
    echo     - Linked folder created...
    echo
}

#
# Set the resolution to the predetermined values.  This will overwrite
# whatever is set in the settings.cfg
#
function resetResolution
{
	sed -i "s/^SCREEN_RESOLUTION_WIDTH.*/SCREEN_RESOLUTION_WIDTH = ${WIDTH}/" ${KSP_DIR}/settings.cfg
	sed -i "s/^SCREEN_RESOLUTION_HEIGHT.*/SCREEN_RESOLUTION_HEIGHT = ${HEIGHT}/" ${KSP_DIR}/settings.cfg
	sed -i "s/^FULLSCREEN.*/FULLSCREEN = False/" ${KSP_DIR}/settings.cfg
}

function finish
{
    echo
    echo     - script complete...
    echo
}

GetKspInstalls

if [ "$n" != "" -a $cnt -gt -1 ]; then
	if [ "$n" -ge 0 -a "$n" -le $cnt ] 2>/dev/null; then
		echo ok
		selected=`echo ${arr[n]} | cut -c59- | sed 's/://g' `
		if [ $WINDOWS = true ]; then
			selected=`echo "${selected,}"`
			selected="/$selected"
		fi
	else
		echo Invalid number entered, exiting
		exit
	fi
fi
[ "$selected" != "" ] && GAME_DIR=$selected



echo -e "\n\n\nSource game directory: $GAME_DIR"
echo 
read -p "Press <return> to use default or enter the source directory: " sd
[ "$selected" != "" ] && GAME_DIR=`echo $selected`
echo "Selected game directory: '$GAME_DIR'"
if [ ! -d "${GAME_DIR}" ]; then
    echo "Source game directory not found, exiting"
    exit
fi

VERSION=""                  # will contain the version number only

cat <<__EOF__
 
Path tokens:
  LCL_DIR: "${LCL_DIR}"
  GAME_DIR: "${GAME_DIR}"    
  GIT_DIR: "${GIT_DIR}"
  KSP_DIR: "${KSP_DIR}"

Let's get the version of the existing game...
__EOF__

# get_versions
steamVer=`grep ^Version "${GAME_DIR}"/readme.txt`

[ -d "${KSP_DIR}" ] && thisVer=`grep ^Version "${KSP_DIR}"/readme.txt`
VERSION="$thisVer"

echo $thisVer
VERSION=`echo $thisVer | cut -f2 -d' '`

echo     - Game Version found is:  $steamVer
[ "$thisVer" != "" ] && echo "   Dev Version found is: $thisVer"
echo
read -p "  - Do you wish to continue? (Y/N):  " quit
if [ "$quit" == "n" -o "$quit" == "N" ]; then
	echo "Terminating batch operation without executing Dev Setup..."
	exit
fi

while [ "$optn" != 'X'  -a "$optn" != 'x' -a "$optn" != 'Q'  -a "$optn" != 'q' ]; do

cat <<_EOF_


     ====================================================
     Main Menu:

     1 - Perform all steps
     2 - Backup existing game folder
     3 - Remove existing game folder
     4 - Create new game folder
     5 - Copy source game folder
     7 - Copy Dev Debug files to Game folder
     8 - Copy Game Save and Ships to Game folder
     9 - Create linked folder
    10 - Reset screen resolution
     R - Run the copied game
 Q | X - Quit script
     ====================================================

_EOF_

    read  -p "Select option (1 - 9, X):  " optn
    echo
    echo     Choice made:  "$optn"
    echo

    case $optn in
        1)  DoAll 
            ;;
        2)  backupGame 
            ;;
        3)  removeGame 
            ;;
        4)  createFolder 
            ;;
        5)  copyGame 
            ;;
        7)  copyDebugFiles 
            ;;
        8)  copyGameSaves 
            ;;
        9)  createLinkedFolder 
            ;;
		10)	resetResolution
			;;
		r|R)
			cd kspdev
			
			./${KSP_EXE}&
			echo "Starting ${KSP_EXE}\n"
			sleep 5
			cd ..
			echo -e "\n\n"
			;;
    esac

done
