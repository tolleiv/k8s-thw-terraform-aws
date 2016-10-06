
resource "null_resource" "cfssl" {
  provisioner "local-exec" {
    command = "./ca-scripts/create-ca.sh"
  }
}

resource "null_resource" "kubernetes-cert" {

  depends_on = ["null_resource.cfssl"]

  provisioner "local-exec" {
    command = <<EOT
cat > ca/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "ip-10-240-0-20",
    "ip-10-240-0-21",
    "ip-10-240-0-22",
    "10.32.0.1",
    "${join("\", \"", aws_instance.controller.*.private_ip)}",
    "${join("\", \"", aws_instance.controller.*.private_dns)}",
    "${join("\", \"", aws_instance.controller.*.tags.Name)}",
    "${join("\", \"", aws_instance.worker.*.private_ip)}",
    "${join("\", \"", aws_instance.worker.*.private_dns)}",
    "${join("\", \"", aws_instance.worker.*.tags.Name)}",
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
ca-scripts/create-cert.sh
EOT
  }
}

resource "null_resource" "copy-cert-workers" {
  count = "${var.instance_controller_count + var.instance_worker_count}"
  triggers {
    instance_ips = "${join(",", concat(aws_instance.controller.*.public_ip,aws_instance.worker.*.public_ip))}"
  }

  depends_on = ["null_resource.kubernetes-cert"]

  connection {
    host = "${element(concat(aws_instance.controller.*.public_ip,aws_instance.worker.*.public_ip), count.index)}"
    user = "ubuntu"
    private_key = "${file("ssh/kubernetes_the_hard_way")}"
  }

  provisioner "file" {
    source = "ca/ca.pem"
    destination = "/home/ubuntu/ca.pem"
  }
  provisioner "file" {
    source = "ca/kubernetes-key.pem"
    destination = "/home/ubuntu/kubernetes-key.pem"
  }
  provisioner "file" {
    source = "ca/kubernetes.pem"
    destination = "/home/ubuntu/kubernetes.pem"
  }
}