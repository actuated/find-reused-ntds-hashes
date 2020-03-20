#!/bin/bash
# find-reused-ntds-hashes.sh (v2.0)
# v1.0 - 11/04/2017 by Ted R (http://github.com/actuated)
# v2.0 - 03/20/2020 Rewrite with new options
dateCreated="11/4/2017"
dateLastMod="3/20/2020"

dtStamp=$(date +%F-%H-%M)
fileTemp="temp-frnh-$dtStamp.txt"
fileOutCount="reused-hashes-by-count-$dtStamp.txt"
fileOutUsers="reused-hashes-with-users-$dtStamp.txt"
pathOut="."
formatUsername="NODOMAIN"
findMode="N"

function fnUsage {
  echo
  echo "Script for checking NTDS dumps/NTLM password hash lists for duplicate password hashes"
  echo "between user accounts."
  echo
  echo "Created $dateCreated, last modified $dateLastMod."
  echo
  echo "======================================[ usage ]======================================"
  echo
  echo "./find-reused-ntds-hashes.sh [NTDS file] [options]"
  echo
  echo "[NTDS file]"
  echo
  echo "--out-dir [directory]   Optionally specify an output directory for the two files."
  echo
  echo "--find-list [file]      Check usernames against a list and color results using grep"
  echo "                        output. Case insensitive, but must match the whole string."
  echo "                        Meant to let you supply a list of admins and highlight them"
  echo "                        if they appear in the output. Optional."
  echo
  echo "--preserve-domain       Optionally display usernames with any domain name they had in"
  echo "                        the original input file."
  echo
  echo "=======================================[ fin ]======================================="
  echo
}

echo
echo "==============[ find-reused-ntds-hashes.sh - Ted R (github: actuated) ]=============="

if [ -f "$1" ]; then
  fileInput="$1"
  checkForHashes=$(grep ".*:*:................................:................................" "$fileInput" | wc -l)
  if [ "$checkForHashes" = "0" ]; then
    echo
    echo "Error: Expected format for NTLM password hashes/NTDS output not found."
    echo "Checking with: 'grep .*:*:................................:................................'."
    fnUsage
    exit
  fi
else
  echo
  echo "Error: '$1' does not exist or is not a file."
  fnUsage
  exit
fi

# Read Options
shift
while [ "$1" != "" ]; do
  case "$1" in
  --out-dir )
    shift
    pathOut="$1"
    if [ -e "$pathOut" ] && [ ! -d "$pathOut" ]; then
      echo
      echo "Error: '$pathOut' exists, but is not a directory."
      fnUsage
      exit
    fi
    ;;
  --find-list )
    findMode="LIST"
    shift
    fileFind="$1"
    if [ ! -f "$fileFind" ]; then
      echo
      echo "Error: --find-list used, but '$fileFind' does not exist as a file."
      fnUsage
      exit
    fi
    ;;
  --preserve-domain )
    formatUsername="WITHDOMAIN"
    ;;
  * )
    echo
    echo "Error: Input not recognized."
    fnUsage
    exit
    ;;
  esac
  shift
done

# Get reused NT hashes
grep ".*:*:................................:................................" "$fileInput" | awk -F : '{print $4}' | sort | uniq -c | awk '{print $1 " x " $2}' | sort -Vr | grep -v '^1 x' > "$pathOut"/"$fileOutCount"

# Check for reused-hashes-by-count output file before checking for users
if [ -f "$pathOut"/"$fileOutCount" ]; then
  # reused-hashes-by-count should be created, but empty, if no duplicates were found
  # Check for its length before checking for users
  countReusedHashes=$(wc -l "$pathOut"/"$fileOutCount" | awk '{print $1}')
  if [ "$countReusedHashes" != "0" ]; then
    echo
    echo "Found $countReusedHashes NT password hashes reused."
    mostReused=$(head -n 1 "$pathOut"/"$fileOutCount" | awk '{print $1}')
    echo "The most-reused hash was reused $mostReused times."
    echo
    echo "$pathOut/$fileOutCount created."
    # Check for corresponding users
    while read -r "thisLine"; do
      thisHash=$(echo "$thisLine" | awk '{print $3}')
      thisUserList=""
        grep ":................................:$thisHash" "$fileInput" | tr 'A-Z' 'a-z' > "$pathOut"/"$fileTemp"
        while read -r "thisResult"; do
          if [ "$formatUsername" = "NODOMAIN" ]; then
            # Unless specified to preserve domains, check usernames for domain and drop it
            checkForDomain=$(echo "$thisResult" | grep '\\')
            if [ "$checkForDomain" != "" ]; then
              thisUser=$(echo "$thisResult" | awk -F \\ '{print $2}' | awk -F: '{print $1}')
            else
              thisUser=$(echo "$thisResult" | awk -F: '{print $1}')
            fi
          else
            thisUser=$(echo "$thisResult" | awk -F: '{print $1}')
          fi
          # Find users to highlight from a list
          if [ "$findMode" = "LIST" ]; then
            checkThisUser=$(grep -iw "$thisUser" "$fileFind" --color=always)
            if [ "$checkThisUser" != "" ]; then
              thisUser="$checkThisUser"
            fi
          fi
          # Add user to rolling CSV list for this hash
          thisUserList+=",$thisUser"
        done < "$pathOut"/"$fileTemp"
      # Begin output for file with users
      echo "$thisLine" >> "$pathOut"/"$fileOutUsers"
      echo "$thisUserList" | tr , "\n" | sort | tr "\n" , | sed 's/^,//g' | sed 's/,$//g' | sed 's/,/, /g' >> "$pathOut"/"$fileOutUsers"
      echo >> "$pathOut"/"$fileOutUsers"
      echo >> "$pathOut"/"$fileOutUsers"
    done < "$pathOut"/"$fileOutCount"
    # Cleanup and end
    if [ -f "$pathOut"/"$fileTemp" ]; then rm "$pathOut"/"$fileTemp"; fi
    if [ -f "$pathOut"/"$fileOutUsers" ]; then
      echo
      echo "$pathOut/$fileOutUsers created."
      echo
      echo "=======================================[ fin ]======================================="
      echo
      exit
    fi
  else
    # If reused-hashes-by-count exists with 0 lines
    echo
    echo "Error: No reused NT hashes found, deleting '$fileOutCount'."
    if [ -f "$pathOut"/"$fileOutCount" ]; then rm "$pathOut"/"$fileOutCount"; fi
    echo
    echo "=======================================[ fin ]======================================="
    echo
    exit
  fi
else
  # If reused-hashes-by-count was not created
  echo
  echo "Error: No reused NT hashes found, '$fileOutCount' not created."
  echo
  echo "=======================================[ fin ]======================================="
  echo
  exit
fi
