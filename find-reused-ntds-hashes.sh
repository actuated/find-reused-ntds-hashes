#!/bin/bash
# find-reused-ntds-hashes.sh (v1.0)
# v1.0 - 11/04/2017 by Ted R (http://github.com/actuated)

varOutCount="reused-hashes-by-count.txt"
varOutUsers="reused-hashes-with-users.txt"
varYMDHM=$(date +%F-%H-%M)
varTempAllHashes="frntdsh-temp-all-$varYMDHM.txt"
varTempUniqHashes="frntdsh-temp-uniq-$varYMDHM.txt"
varTempUnsortedCount="frntdsh-temp-count-$varYMDHM.txt"

echo
echo "==============[ find-reused-ntds-hashes.sh - Ted R (github: actuated) ]=============="

if [ ! -f "$1" ]; then
  echo
  echo "Error: No Input File Specified"
  echo "./find-reused-ntds-hashes.sh [input file]"
  echo
  echo "Looking for: user:rid:lmhash:ntlmhash"
  echo
  echo "=======================================[ fin ]======================================="
  echo
  exit
fi

if [ -f "$varOutCount" ]; then
  echo
  echo "Error: $varOutCount already exists."
  echo
  echo "=======================================[ fin ]======================================="
  echo
  exit
fi

if [ -f "$varOutUsers" ]; then
  echo
  echo "Error: $varOutUsers already exists."
  echo
  echo "=======================================[ fin ]======================================="
  echo
  exit
fi

if [ -f "$varTempAllHashes" ]; then rm "$varTempAllHashes"; fi
if [ -f "$varTempUniqHashes" ]; then rm "$varTempUniqHashes"; fi
if [ -f "$varTempUnsortedCount" ]; then rm "$varTempUnsortedCount"; fi

varCheckForHashes=$(grep .*:*:................................:................................ "$1" | wc -l)
if [ $varCheckForHashes = 0 ]; then
  echo
  echo "Error: $1 doesn't seem to contain any NTLM hashes."
  echo "Grepping for: .*:*:................................:................................"
  echo
  echo "=======================================[ fin ]======================================="
  echo
  exit
else
  echo
  echo "Found $varCheckForHashes hashes."
fi

grep .*:*:................................:................................ "$1" > "$varTempAllHashes"
awk -F: '{print $3 ":" $4}' "$varTempAllHashes" | sort | uniq > "$varTempUniqHashes"

varCheckForUniques=$(wc -l "$varTempUniqHashes" | awk '{print $1}')
if [ "$varTempUniqHashes" = "wc" ]; then
  echo
  echo "Error: Didn't find any user:rid:lmhash:ntlmhash hashes to check for repeats with."
  echo
  echo "=======================================[ fin ]======================================="
  echo
  exit
else
  echo "Found $varCheckForUniques unique password hashes."
fi

varHighest=0
varCountTimes=0
varCountTotal=0
while read varLine; do
  varCountReuse=$(grep "$varLine" "$varTempAllHashes" | wc -l)
  if [ $varCountReuse -gt 1 ]; then
    echo -e "$varCountReuse\tx\t$varLine" >> "$varTempUnsortedCount"
    let varCountTimes=varCountTimes+1
    let varCountTotal=varCountTotal+varCountReuse
    if [ $varCountReuse -gt $varHighest ]; then
      let varHighest=varCountReuse
    fi
  fi
done < "$varTempUniqHashes"

if [ ! -f "$varTempUnsortedCount" ]; then
  echo
  echo "Didn't find any hashes appearing more than once."
  echo
  echo "=======================================[ fin ]======================================="
  echo
  if [ -f "$varTempAllHashes" ]; then rm "$varTempAllHashes"; fi
  if [ -f "$varTempUniqHashes" ]; then rm "$varTempUniqHashes"; fi
  exit
else
  sort -nr "$varTempUnsortedCount" > "$varOutCount"
  echo "Found $varCountTimes hashes reused a total of $varCountTotal times."
  echo "The most reused password hash was found $varHighest times."
  echo
  echo "Reused hashes ordered by count saved as $varOutCount."
fi

# while read varLine; do varHash=$(echo "$varLine" | awk '{print $3}'); echo "$varLine"; grep $varHash combined-ntds.txt | awk -F: '{print $1}' | column; echo; done < reused-by-count.txt > reused-by-count-with-usernames.txt

while read varLine; do
  varThisHash=$(echo "$varLine" | awk '{print $3}')
  echo "$varLine" >> "$varOutUsers"
  grep "$varThisHash" "$varTempAllHashes" | awk -F: '{print $1}' | column >> "$varOutUsers"
  echo >> "$varOutUsers"
done < "$varOutCount"

if [ -f "$varOutUsers" ]; then
  echo
  echo "Reused hashes ordered by count with users saved as $varOutUsers."
fi

if [ -f "$varTempAllHashes" ]; then rm "$varTempAllHashes"; fi
if [ -f "$varTempUniqHashes" ]; then rm "$varTempUniqHashes"; fi
if [ -f "$varTempUnsortedCount" ]; then rm "$varTempUnsortedCount"; fi
echo
echo "=======================================[ fin ]======================================="
echo
