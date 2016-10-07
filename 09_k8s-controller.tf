#
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-kubernetes-controller.md
#
resource "null_resource" "provision-k8s-controller" {
  depends_on = [
    "null_resource.provision-etcd", "null_resource.kubernetes-cert"]

  count = "${var.instance_controller_count}"
  triggers {
    instance_ips = "${join(",", aws_instance.controller.*.id)}"
  }

  connection {
    host = "${element(aws_instance.controller.*.public_ip, count.index)}"
    user = "ubuntu"
    private_key = "${file("ssh/kubernetes_the_hard_way")}"
  }

  provisioner "file" {
    source = "config/token.csv"
    destination = "/home/ubuntu/token.csv"
  }

  provisioner "file" {
    source = "config/auth-policy.jsonl"
    destination = "/home/ubuntu/authorization-policy.jsonl"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/lib/kubernetes",
      "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /var/lib/kubernetes/",
      "wget -q https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kube-apiserver",
      "wget -q https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kube-controller-manager",
      "wget -q https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kube-scheduler",
      "wget -q https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kubectl",
      "chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl",
      "sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/",
      "sudo mv token.csv /var/lib/kubernetes/",
      "sudo mv authorization-policy.jsonl /var/lib/kubernetes/"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<\"EOF\" | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \\
  --admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota \\
  --advertise-address=${element(aws_instance.controller.*.private_ip, count.index)} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --authorization-mode=ABAC \\
  --authorization-policy-file=/var/lib/kubernetes/authorization-policy.jsonl \\
  --bind-address=0.0.0.0 \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --insecure-bind-address=0.0.0.0 \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --service-account-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --token-auth-file=/var/lib/kubernetes/token.csv \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kube-apiserver",
      "sudo systemctl start kube-apiserver",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<\"EOF\" | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-controller-manager \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --leader-elect=true \\
  --master=http://${element(aws_instance.controller.*.private_ip, count.index)}:8080 \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kube-controller-manager",
      "sudo systemctl start kube-controller-manager",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<\"EOF\" | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \\
  --leader-elect=true \\
  --master=http://${element(aws_instance.controller.*.private_ip, count.index)}:8080 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kube-scheduler",
      "sudo systemctl start kube-scheduler"
    ]
  }
}

resource "aws_elb_attachment" "controller" {
  count = "${var.instance_controller_count}"
  elb      = "${aws_elb.kubernetes.id}"
  instance = "${element(aws_instance.controller.*.id, count.index)}"
}