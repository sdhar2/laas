#!/bin/sh

echo "--- Validating ---"

#does openssl exist?
command -v openssl >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "--- Error: openssl command not found, exit ---"
  exit 1;
fi

if [[ ! -f distinguish_names.cnf ]]; then
  echo "--- Error: distinguish_names.cnf not found, exit ---"
  exit 1;
fi

#parse the distinguish_names.cnf to get the names
while read line
do
  name=`echo $line | cut -d ":" -f1`
  if [[ $name == "CN" ]]; then
    cn_value=`echo $line | cut -d ":" -f2`
  elif [[ $name == "OU" ]]; then
    ou_value=`echo $line | cut -d ":" -f2`
  elif [[ $name == "O" ]]; then
    o_value=`echo $line | cut -d ":" -f2`
  elif [[ $name == "C" ]]; then
    c_value=`echo $line | cut -d ":" -f2`
  fi
done < distinguish_names.cnf

echo "--- Parsed distinguish_names.cnf, CN=$cn_value, OU=$ou_value, O=$o_value, C=$c_value ---"

echo "--- Creating private key ---"

openssl genrsa -out server-private-key-nopassphrase.pem 2048

echo "--- Creating CSR (Certificate Signing Request) ---"
#substitute SAN DNS with FQDN from the CN field
prefix=`echo $cn_value | cut -d. -f1`
domain=${cn_value#$prefix}

sed -i "s/FQDN_MACRO/$domain/g" openssl.cnf

subject_line="/CN=$cn_value/OU=ELK/OU=$ou_value/O=$o_value/C=$c_value"
openssl req -new -newhdr -sha256 -nodes -key server-private-key-nopassphrase.pem -days 720 -out elk.csr -subj "$subject_line" -config openssl.cnf

echo "--- Done ---"
