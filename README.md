# find-reused-ntds-hashes
Shell script to check a file containing NTLM hashes for repeated hashes.

# Usage
```
./find-reused-ntds-hashes.sh [input file]
```
 - **[input file]** is used to specify a list of hashes. The expected format is `user:rid:lmhash:nthash`.
 - Provides a count of:
   - Total hashes
   - Unique hashes
   - Number of hashes reused
   - Combined total of number of times hashes were reused
   - The number of times the most-reused hash was found
 - Output includes:
   - **reused-hashes-by-count.txt** lists unique hashes repeated, sorted by the number of times reused, formatted as `count	x	lmhash:nthash`.
   - **reused-hashes-with-users.txt** lists usernames in columns following each line of **reused-hashes-by-count.txt**.
