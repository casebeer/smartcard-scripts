#!/usr/bin/env bash

# import a PEM RSA private key to the PIV-II applet and install a self signed certificate
# Examples of PEM RSA private keys are:
# - ssh client private key files and
# - the output of openssl genrsa -out key.pem 2048
#
# Based on Kevin McArthur's instructions at https://www.youtube.com/watch?v=fBlsmbhMPok
#

KEY=$1
TOOL=yubico-piv-tool
SLOT=9a
DN='/CN=Smartcard Certificate/'
OUTPUT_CERT_FILE=cert.pem
PIN=123456

read -p "Enter smartcard PIN: " -s PIN

echo "Importing private key to smartcard slot $SLOT..."
$TOOL -s $SLOT -a import-key < $KEY

if [ $? -neq 0 ]; then
	echo "Failed to load private ket to smartcard slot $SLOT. Exiting."
	exit 1
fi

echo "Generating self signed certificate..."
openssl rsa -in $KEY -pubout | tee $OUTPUT_CERT_FILE | $TOOL -s $SLOT -S "${DN}" -P $PIN -a verify -a selfsign | pbcopy

if [ $? -neq 0 ]; then
	echo "Failed to generate self signed certificate. Exiting."
	exit 2
fi

echo "Certificate saved in $OUTPUT_CERT_FILE"

echo "Deleting old certificate from smartcard slot $SLOT..."
pbpaste | $TOOL -s $SLOT -a delete-certificate

if [ $? -neq 0 ]; then
	echo "Failed to delete old certificate from smartcard. Exiting."
	exit 3
fi

echo "Importing certificate to smartcard slot $SLOT..."
pbpaste | $TOOL -s $SLOT -a import-certificate

if [ $? -neq 0 ]; then
	echo "Failed to load new certificate to smartcard. Exiting."
	exit 4
fi

