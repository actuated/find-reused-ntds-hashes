# find-reused-ntds-hashes
Shell script to check a file containing NTLM hashes for repeated hashes.

# Usage
```
./find-reused-ntds-hashes.sh [input file] [options]
```
 - **[input file]** is used to specify a list of hashes. The expected format is `user:rid:lmhash:nthash`.
 - **--file-list [list]** optionally lets you highlight users in the output based on a target list of users.
   - Matches are case-insensitive, but must be the complete string (username).
   - Color output relies on `grep ... --color=always`.
 - **--preserve-domain** optionally shows the domain name for users in the output (the default is to drop it).
   - This will not add domains for users that did not have one listed in the input file.
 - Output includes:
   - **reused-hashes-by-count-[datestamp].txt** lists unique hashes repeated, sorted by the number of times reused, formatted as `count	x nthash`.
   - **reused-hashes-with-users-[datestamp].txt** lists usernames in columns following each line of **reused-hashes-by-count.txt**.
