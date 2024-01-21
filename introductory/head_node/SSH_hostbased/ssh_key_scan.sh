#!/bin/bash

DIR=files

rm ${DIR}/ssh_known_hosts

for i in $(cat "${DIR}"/hosts.equiv)
do

#ssh-keyscan -t rsa $i >> ~/.ssh/known_hosts
ssh-keyscan -t rsa ${i} >> ${DIR}/ssh_known_hosts
 

done

