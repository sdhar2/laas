#!/bin/sh

echo "--- Validating ---"

#does openssl exist?
command -v openssl >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "--- Error: openssl command not found, exit ---"
  exit 1;
fi

#verify input argument
if [[ $# -ne 1 ]] || [[ -z $1 ]]; then
  echo "--- PKIWorks certificate zip file must be supplied, exit ---"
  exit 1;
fi

ls $1 
if [[ $? -ne 0 ]]; then
  echo "--- Error: specified PKIWorks certificate zip file not found, exit ---"
  exit 1;
fi

#unzip and package the certificates

echo "--- Unzipping and packaging certificates ---"
#parse the distinguish_names.cnf to get the FQDN which is the name of the certificate file
while read line
do
  name=`echo $line | cut -d ":" -f1`
  if [[ $name == "CN" ]]; then
    cn_value=`echo $line | cut -d ":" -f2`
  fi
done < distinguish_names.cnf

echo "--- Parsed distinguish_names.cnf, CN=$cn_value ---"

unzip $1
unzip innerPackage.zip

openssl x509 -inform der -in $cn_value.cer -out client-cert.pem

openssl x509 -in System\ Infrastructure\ Root\ CA\ SHA256.cer -inform der -out root-ca.pem -outform pem

openssl x509 -in SystemInfrastructure\ SubCA2\ SHA256.cer -inform der -out sub-ca2.pem -outform pem

cat root-ca.pem sub-ca2.pem > ca.pem

#install the packaged pkcs12 file to storage location
echo "--- Installing certificates ---"
cp client-private-key-nopassphrase.pem ca.pem client-cert.pem /home/docker/cloud-service-scripts/certificates/LSF/keys

#cleanup
rm -rf *.pem *.cer *.zip *.csr *.xml *.txt *.signature

echo "--- Done ---"
