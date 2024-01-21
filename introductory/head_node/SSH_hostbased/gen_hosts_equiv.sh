#!/bin/bash

DIR=files

grep 192.168 /etc/hosts | cut -f1 > ${DIR}/hosts.equiv
grep 192.168 /etc/hosts | cut -f2 >> ${DIR}/hosts.equiv
