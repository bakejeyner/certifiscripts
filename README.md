# Certificate Scripts
This directory is responsible for generating a CA, private keys, certificates, keystores, and truststores in user specified locations.

## conf/
Contains openssl configuration files used by the gencerts.sh script.

# CA/
This directory contains the CA private key and certificate for use when generating.

# output/
This directory contains the output of the gencerts.sh script.

## gencerts.sh
This script is responsible for generating a CA, private keys, certificates, keystores, and truststores in user specified locations.
The script will walk you through the many available options for certificate generation.
Note that you can provide your own CA private key (./CA/ca.key) and certificate (./CA/ca.crt) for generation if you like.

## cleancerts.sh
This script is responsible for cleaning up all the work performed by the gencerts script.
IOW deleting the output directory :smirk:
