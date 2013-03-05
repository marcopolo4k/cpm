#!/bin/bash
#
echo "Starting scan at: "; date; echo
for sorted_associated_lib in $(
 for file in $(strings /etc/ld.so.cache | grep / | egrep -vi "pam.d|memcache|libevent|libhashkit" | sort | uniq); do
  if [ ! -d $file ]; then
   if [ -h $file ]; then
    file=$(readlink -f $file)
   fi
   associated_lib=$(rpm -qf $file)
   orphan_file=$(echo $associated_lib | grep 'not owned by any package')
   if [ "$orphan_file" ]; then
    echo -e $file"_is_not_owned_by_any_package"
   else
    echo $associated_lib
   fi
  fi
 done | sort | uniq);
do
 new_orphan_file=$(echo $sorted_associated_lib | grep '_is_not_owned_by_any_package')
 if [ "$new_orphan_file" ]; then
  echo $sorted_associated_lib
 else
  result=$(rpm -V $sorted_associated_lib)
  if [ "$result" ]; then
   printf "\n"$sorted_associated_lib":\n"; rpm -V $sorted_associated_lib
  fi
 fi
done
echo -e "\nFinishing scan at: "; date; echo
