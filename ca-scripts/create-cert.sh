#!/bin/sh


pushd ca
./cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=../ca-config/ca.json \
  -profile=kubernetes \
  kubernetes-csr.json | ./cfssljson -bare kubernetes