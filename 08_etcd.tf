
resource "null_resource" "provision-etcd" {
  depends_on = ["null_resource.copy-cert-workers"]

  count = "${var.instance_controller_count}"
  triggers {
    instance_ips = "${join(",", aws_instance.controller.*.id)}"
  }

  depends_on = ["null_resource.kubernetes-cert"]

  connection {
    host = "${element(concat(aws_instance.controller.*.public_ip), count.index)}"
    user = "ubuntu"
    private_key = "${file("ssh/kubernetes_the_hard_way")}"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo mkdir -p /etc/etcd/",
        "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/",
        "test -f etcd-v3.0.10-linux-amd64.tar.gz && rm etcd-v3.0.10-linux-amd64.tar.gz",
        "wget -q https://github.com/coreos/etcd/releases/download/v3.0.10/etcd-v3.0.10-linux-amd64.tar.gz",
        "tar -xf etcd-v3.0.10-linux-amd64.tar.gz",
        "sudo mv etcd-v3.0.10-linux-amd64/etcd* /usr/bin/",
        "sudo mkdir -p /var/lib/etcd",
        "cat <<\"EOF\" | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/bin/etcd --name controller${count.index} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --initial-advertise-peer-urls https://${element(concat(aws_instance.controller.*.private_ip), count.index)}:2380 \\
  --listen-peer-urls https://${element(concat(aws_instance.controller.*.private_ip), count.index)}:2380 \\
  --listen-client-urls https://${element(concat(aws_instance.controller.*.private_ip), count.index)}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls https://${element(concat(aws_instance.controller.*.private_ip), count.index)}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller0=https://10.240.0.10:2380,controller1=https://10.240.0.11:2380,controller2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
" ,
      "sudo systemctl daemon-reload",
      "sudo systemctl enable etcd",
      "sudo systemctl start etcd",
]
  }
}