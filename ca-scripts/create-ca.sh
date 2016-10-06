#!/bin/sh

test -d ./ca || mkdir ca

if [ ! -f ./ca/cfssl ]; then
    wget -q https://pkg.cfssl.org/R1.2/cfssl_darwin-amd64
    chmod +x cfssl_darwin-amd64
    mv cfssl_darwin-amd64 ca/cfssl

    wget -q https://pkg.cfssl.org/R1.2/cfssljson_darwin-amd64
    chmod +x cfssljson_darwin-amd64
    mv cfssljson_darwin-amd64 ca/cfssljson
fi

if [ ! -f ./ca/ca.pem ]; then
    pushd ca
    ./cfssl gencert -initca ../ca-config/ca-csr.json | ./cfssljson -bare ca
fi