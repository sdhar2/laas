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

openssl genrsa -out client-private-key-nopassphrase.pem 2048

echo "--- Creating CSR (Certificate Signing Request) ---"

subject_line="/CN=$cn_value/OU=LSC/OU=$ou_value/O=$o_value/C=$c_value"
openssl req -new -newhdr -sha256 -nodes -key client-private-key-nopassphrase.pem -days 720 -out lsc.csr -subj "$subject_line"

echo "--- Done ---"
