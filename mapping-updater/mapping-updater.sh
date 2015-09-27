#!/bin/bash

############################################################################
## This scripts takes MCPBot Exports (fields.csv, methods.csv, params.csv) and
## makes a dumb replace of all occurrences in your java source code
##
## Author: EoD
############################################################################

#pre-checks
if ! hash find 2>/dev/null; then
    echo "Can't find \"find\". Stopping."
    exit 1
elif ! hash sed 2>/dev/null; then
    echo "Can't find \"sed\". Stopping."
    exit 1
elif ! hash xargs 2>/dev/null; then
    echo "Can't find \"xargs\". Stopping."
    exit 1
fi

path="src/"
files=()

#usage
if [ "$#" -lt 1 ] || [ "$1" == "--help" ]; then
    echo "No parameters specified."
    echo "Usage: update-mapping [-s PATH] MCPBot_FILES..."
    exit 1
else
    if [ "$#" -ge 3 ] && [ "$1" == "-s" ]; then
	echo "Setting path to \"$2\"."
	path="$2"

	#remove first two elements from args
	while (( $#-2 )); do
	    files+=($3)
	    shift
	done
    else
	echo "Using default path \"$path\"."
	files=( "$@" )
    fi
fi


#main bit
replace_filename="mapping-updater.sed"
rm ${replace_filename}	#reset file

echo -n "Creating ${replace_filename} out of "
printf '%s, ' "${files[@]}"
echo

for file in "${files[@]}"
do
  echo " Adding $file..."

  while IFS='' read -r line || [[ -n "$line" ]]
  do
      IFS="," read -ra mapping_line <<< "$line"
      
      str_replace="s/${mapping_line[0]}/${mapping_line[1]}/g"
      echo $str_replace >> $replace_filename
  done < <(sed 1d "${file}")

done

if [ "$#" -eq 2 ]; then
  echo "Finished creating ${replace_filename}. Replacing java files in $2 now..."

  #single-threaded version
  #find $path -type f -iname "*.java" -exec sed -f $replace_filename -i {} \;

  #parallel version
  find $path -type f -iname "*.java" -print0 | xargs -0 -n 240 -P 8 sed -f $replace_filename -i

  echo "Finished replacing. Stopping..."
else
  echo "No path specified, only created ${replace_filename}. Stopping..."
fi
