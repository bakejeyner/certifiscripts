#!/bin/bash

# This script is responsible for generating a CA, private keys, certificates, keystores, and truststores in user specified locations.

# !Important Notes!
# CD into this directory before running this script or else there will be relative pathing issues!
# This script requires opensll. openssl is installed by default on Mac/Linux; Windows users can download binaries here https://slproweb.com/products/Win32OpenSSL.html.

# For some useful openssl commands: https://www.sslshopper.com/article-most-common-openssl-commands.html.
# For information on how to set up a CA in openssl: https://stackoverflow.com/a/21340898.

# This comment section describes the commands to execute if you wish to perform the steps manually.
#
# To generate a CA private key and cert:
# openssl req -config ./conf/ca.cnf -x509 -days 3000 -newkey rsa:4096 -sha256 -nodes -keyout ../certs/ca.key -out ../certs/ca.crt
#
# To generate a server private key and CSR:
# openssl req -config ./conf/server.cnf -newkey rsa:2048 -sha256 -nodes -keyout ./server.key -out ./server.csr
#
# To sign a CSR with a CA:
# openssl ca -config ./conf/ca.cnf -policy signing_policy -extensions signing_req -out ./server.crt -infiles ./server.csr
#
# To create a PKCS12 keystore from a certificate:
# keytool -import -file ./server.crt -alias localhost -keystore ./keystore.p12
#
# To create a PKCS12 keystore from a private key and certificate:
# openssl pkcs12 -export -in ./server.crt -inkey ./server.key -out ./keystore.p12 -name localhost

# isYes  is a function that checks to see if the yesVar variable is "Y" or "YES" ignoring case, and set the yesResult variable appropriately
isYes() {
    if [ "$yesVar" = "y" ]|| [ "$yesVar" = "Y" ] || [ "$yesVar" = "yes" ] || [ "$yesVar" = "Yes" ] || [ "$yesVar" = "YES" ];
    then
        true
    else
        false
    fi
}

# endScript is a function that ends the script in proper fashion
endScript() {
  read -p "End of script, thank you for chosing bash! Press any key to continue..."
  exit
}

# echoLineSeparator is a function that echos a line separator
echoLineSeparator() {
    echo ""
    echo "###############################################################################################"
    echo ""
}

echo "Welcome to the gencerts script!"
echo "This script is responsible for generating a CA, private keys, certificates, keystores, and truststores in user specified output locations."
echo "Note that this script uses openssl and keytool. See script comments for more information."

echoLineSeparator

# check if an input CA exists
if [ -f "./CA/ca.key" ] && [ -f "./CA/ca.crt" ];
then
    read -p "Existing CA found! Would you like to use this CA for generation? (Y/N): " yesVar
    if isYes;
    then
        useExistingCa=0
        # check if index.txt exists; if not then make it
        if [ ! -f "./CA/index.txt" ];
        then
            touch "./CA/index.txt"
        fi
        # check if serial.txt exists; if not then make it
        if [ ! -f "./CA/serial.txt" ];
        then
            echo "01" > "../CA/serial.txt"
        fi
    fi
else
    echo "Could not find existing CA private key (../certs/ca.key) and/or certificate (../certs/ca.crt). If you wish to use an existing CA for generation, please provide those respective files."
fi

# if not using existing CA, ask to generate one
if [ ! "$useExistingCa" = "0" ];
then
    read -p "Would you like to generate a CA? (Y/N): " yesVar
    if isYes;
    then
        # if CA private key and certificate exist, warn about overwrite
        if [ -f "./CA/ca.key" ] || [ -f "./CA/ca.crt" ];
        then
            read -p "Found existing CA private key (./CA/ca.key) and/or certificate (./CA/ca.crt). Are you sure you want to overwrite? (Y/N): " yesVar
        fi
        if isYes;
        then
            echo "Generating CA."
            rm -r -f "./CA"
            mkdir -p "./CA"
            touch "./CA/index.txt"
            echo "01" > "./CA/serial.txt"
            openssl req -config "./conf/ca.cnf" -x509 -days 3000 -newkey rsa:4096 -sha256 -nodes -keyout "./CA/ca.key" -out "./CA/ca.crt"
        else
            echo "A CA must be provided or generated to continue."
            endScript
        fi
    else
        echo "A CA must be provided or generated to continue."
        endScript
    fi
fi

if [ ! -f "./CA/ca.key" ] || [ ! -f "./CA/ca.crt" ];
then
    echo "Problem locating CA private key (./CA/ca.key) and/or certificate (./CA/ca.crt). Either verify the existence of those files, or try to generate a new CA using this script."
    endScript
fi

echoLineSeparator

read -p "Would you like to generate a truststore for the CA? (Y/N): " yesVar
if isYes;
then
    if [ -f "./CA/truststore.p12" ];
    then
        read -p "Existing truststore (./CA/truststore.p12) found; are you sure you want to overwrite? (Y/N): " yesVar
    fi
    if isYes;
    then
        rm "./CA/truststore.p12"
        read -p "Please provide an alias for the CA in the truststore: " aliasVar
        echo "Generating truststore."
        keytool -import -file "./CA/ca.crt" -alias "$aliasVar" -keystore "./CA/truststore.p12"
    fi
fi

echoLineSeparator

read -p "Would you like to generate a private key and certificate? (Y/N): " yesVar

while isYes;
do
    read -p "Please provide the name of the output directory you would like to generate the new private key and certificate under: " dirVar

    # if private key and certificate already exist, warn about overwrite
    if [ -f "./output/$dirVar/server.key" ] || [ -f "./output/$dirVar/server.crt" ];
    then
        read -p "Existing privake key (./output/$dirVar/server.key) and/or certificate (./output/$dirVar/server.crt) found; are you sure you want to overwrite? (Y/N): " yesVar
    fi

    # generate private key and certificate
    if isYes;
    then
        echo "Generating private key and certificates."
        rm -r -f "./output/$dirVar"
        mkdir -p "./output/$dirVar"
        openssl req -config "./conf/server.cnf" -newkey rsa:2048 -sha256 -nodes -keyout "./output/$dirVar/server.key" -out "./output/$dirVar/server.csr"
        openssl ca -config "./conf/ca.cnf" -policy signing_policy -extensions signing_req -out "./output/$dirVar/server.crt" -infiles "./output/$dirVar/server.csr"
    fi

    echoLineSeparator

    # ask to generate keystore
    read -p "Would you like to generate a keystore for the private key and certificate? (Y/N): " yesVar
    if isYes;
    then
      # if truststore already exists, warn about overwrite
      if [ -f "./output/$dirVar/keystore.p12" ];
      then
          read -p "Existing keystore (./output/$dirVar/keystore.p12) found; are you sure you want to overwrite? (Y/N): " yesVar
      fi
      if isYes;
      then
          read -p "Please provide an alias for the private key and certificate in the keystore: " aliasVar
          echo "Generating keystore."
          openssl pkcs12 -export -in "./output/$dirVar/server.crt" -inkey "./output/$dirVar/server.key" -out "./output/$dirVar/keystore.p12" -name "$aliasVar"
      fi
    fi

    echoLineSeparator

    # ask about generating another
    read -p "Would you like to generate another private key and certificate? (Y/N): " yesVar
done

echoLineSeparator

endScript
