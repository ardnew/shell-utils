#!/bin/bash

#
# compares the files in this environment WC directory to the corresponding files
# actually installed on the system. this is useful to make sure you haven't made
# any local changes that you'd like to be sure get committed to the svn repo.
#
# be sure to also run `svn stat` here to make sure you haven't made any local 
# changes or additions -in this WC directory- that might not be what you intend 
# for the svn repo.
#

for i in * 
do 
  printf "\n\n===\n$i\n===\n"
  diff ~/.$i $i 2>&1
done
