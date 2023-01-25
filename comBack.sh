#!/bin/bash

### Colors
MAIN='\033[0;35m' # purple
ACCENT='\033[1;32m' # yellow 
NOCOLOR='\033[0m' 

### Help Function:
Help() {
  echo "Syntax:     compose-backup [OPTION] SOURCE DESTINATION" 
  echo "Example:    compose-backup -m /home/user/dockers /home/user/dc-backups"
  echo
  echo "Options:"
  echo "-h     Print this Help."
  echo "-m     Markdown mode: export all composes converted to markdown."
  echo "-s     Single mode: export all composes in one directory, prefixed by name of parent directory."
  echo "-t     Tree mode: export all composes with their parent directory."
  echo "-a     All modes together."
  echo "-p     Print resulting destination directory tree."
}

while getopts "hmtsap" options; do
  case "${options}" in
    h) Help;  exit 0;;
    m) MARKDOWN=1 ;;
    t) TREE=1 ;;
    s) SINGLE=1 ;;
    a) SINGLE=1 ; TREE=1 ; MARKDOWN=1 ;;
    p) PTREE=1 ;;
    *) Help; exit 0;;
  esac
done

if (( $OPTIND == 1 )); then
  Help; exit 1
fi
### set $1 back to $1 
shift "$((OPTIND-1))"

### Check if source+destination is set, else set predefined:
[[ -z "$1" ]] && DOCKERS="/home/$USER/dockers/" || DOCKERS="$1"
[[ -z "$2" ]] && BACKUPS="/home/$USER/docker-backups/" || BACKUPS="$2"

### Remove trailing slash and add subdir+file bit:
FILES="$(echo "$DOCKERS" | sed 's:/*$::')/**/docker-compose.y*ml"
echo -e "${ACCENT}Backing up:${NOCOLOR} $(echo "$DOCKERS" | sed 's:/*$::')"
BKDIR="$(echo "$BACKUPS" | sed 's:/*$::')/$(/bin/date +\%Y\%m\%d\%H\%M)"
echo -e "${ACCENT}Destination:${NOCOLOR} $(echo "$BACKUPS" | sed 's:/*$::')/$(/bin/date +\%Y\%m\%d\%H\%M)"
echo

### Check if directory exists
if [ -d "$BKDIR" ] ; then 
  echo "Directory $BKDIR already exists, are you sure? y/[n]" 
  read BackYes
  if [ "$BackYes" == "${BackYes#[Yy]}" ] ; then echo "Exit." ; exit; fi
fi

for file in $FILES
do
  if [ "$TREE" ] ; then
    mkdir -p "${BKDIR}/tree/$(basename $(dirname "$file"))"
    cp -- "$file" "${BKDIR}/tree/$(basename $(dirname "$file"))/$(basename $file)"
  fi
  if [ "$SINGLE" ] ; then
    mkdir -p "${BKDIR}/all"
    cp -- "$file" "${BKDIR}/all/$(basename $(dirname "$file"))_$(basename $file)"
  fi
  if [ "$MARKDOWN" ] ; then
    mkdir -p "${BKDIR}/markdowns"
    ## insert ```yaml on top row and ``` on last row. Naming as {parentdirectoryname}.md 
    sed "1s/^/$(basename $(dirname "$file"))\n\`\`\`yaml\n/" $file > "${BKDIR}/markdowns/$(basename $(dirname "$file")).md"
    echo "\`\`\`" >> "${BKDIR}/markdowns/$(basename $(dirname "$file")).md"
  fi
done

### print results:
if [ "$SINGLE" ] ; then echo -e "${ACCENT}Exported only composes to:${NOCOLOR} ${BKDIR}/all" ; fi
if [ "$MARKDOWN" ] ; then echo -e "${ACCENT}Exported markdowns to:${NOCOLOR} ${BKDIR}/markdowns" ; fi
if [ "$TREE" ] ; then echo -e "${ACCENT}Exported directory tree to:${NOCOLOR} ${BKDIR}/tree" ; fi
if [ "$PTREE" ] ; then tree ${BKDIR}; fi

exit 0
