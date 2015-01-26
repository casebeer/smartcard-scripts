#!/bin/bash

export SC=/Library/OpenSC/lib/opensc-pkcs11.so
#YPT=yubico-piv-tool
YPT=./tool/bin/yubico-piv-tool

echo "Resetting CHUID..."
$YPT -s 9a -a set-chuid
echo $?

echo "Generating new key..."
$YPT -s 9a -A RSA2048 -a generate | pbcopy
echo $?

echo "Generating self signed certificate..."
pbpaste | $YPT -s 9a -S '/CN=Smart card certificate/' -P 123456 -a verify -a selfsign | pbcopy
echo $?

echo "Importing certificate..."
pbpaste | $YPT -s 9a -a import-certificate
echo $?

echo "Done!"

ssh-keygen -D $SC 

