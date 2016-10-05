
resource "null_resource" "cfssl" {
  provisioner "local-exec" {
    command = <<EOT
wget -q https://pkg.cfssl.org/R1.2/cfssl_darwin-amd64
chmod +x cfssl_darwin-amd64
mv cfssl_darwin-amd64 ca/cfssl
wget -q https://pkg.cfssl.org/R1.2/cfssljson_darwin-amd64
chmod +x cfssljson_darwin-amd64
mv cfssljson_darwin-amd64 ca/cfssljson
pushd ca
./cfssl gencert -initca ca-csr.json | ./cfssljson -bare ca
EOT
  }
}

resource "null_resource" "kubernetes-cert" {

  depends_on = ["null_resource.cfssl"]

  provisioner "local-exec" {
    command = <<EOT
pushd ca
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "worker0",
    "worker1",
    "worker2",
    "ip-10-240-0-20",
    "ip-10-240-0-21",
    "ip-10-240-0-22",
    "10.32.0.1",
    "10.240.0.10",
    "10.240.0.11",
    "10.240.0.12",
    "10.240.0.20",
    "10.240.0.21",
    "10.240.0.22",
    "${aws_elb.kubernetes.dns_name}",
    "127.0.0.1"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Cluster",
      "ST": "Oregon"
    }
  ]
}
EOF
./cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | ./cfssljson -bare kubernetes
EOT
  }
}