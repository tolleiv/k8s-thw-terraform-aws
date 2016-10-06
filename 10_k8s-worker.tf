
resource "null_resource" "provision-k8s-worker" {
  depends_on = [
    "null_resource.provision-k8s-controller", "null_resource.kubernetes-cert"]

  count = "${var.instance_worker_count}"
  triggers {
    instance_ips = "${join(",", aws_instance.worker.*.id)}"
  }

  connection {
    host = "${element(aws_instance.worker.*.public_ip, count.index)}"
    user = "ubuntu"
    private_key = "${file("ssh/kubernetes_the_hard_way")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/lib/kubernetes",
      "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /var/lib/kubernetes/",
      "test -f docker-1.12.1.tgz && rm docker-1.12.1.tgz",
      "wget -q https://get.docker.com/builds/Linux/x86_64/docker-1.12.1.tgz",
      "tar -xf docker-1.12.1.tgz",
      "sudo cp docker/docker* /usr/bin/",
      "cat <<\"EOF\" | sudo tee /etc/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
ExecStart=/usr/bin/docker daemon \\
  --iptables=false \\
  --ip-masq=false \\
  --host=unix:///var/run/docker.sock \\
  --log-level=error \\
  --storage-driver=overlay
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/cni",
      "wget -q https://storage.googleapis.com/kubernetes-release/network-plugins/cni-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz",
      "sudo tar -xf cni-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz -C /opt/cni",
      "wget -q https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kubectl",
      "wget -q https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kube-proxy",
      "wget -q https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kubelet",
      "chmod +x kubectl kube-proxy kubelet",
      "sudo mv kubectl kube-proxy kubelet /usr/bin/",
      "sudo mkdir -p /var/lib/kubelet/",
      "cat <<\"EOF\" | sudo tee /var/lib/kubelet/kubeconfig
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/ca.pem
    server: https://10.240.0.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet
  name: kubelet
current-context: kubelet
users:
- name: kubelet
  user:
    token: CHANGETHIS
EOF",
      "cat <<\"EOF\" | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/kubelet \\
  --allow-privileged=true \\
  --api-servers=https://10.240.0.10:6443,https://10.240.0.11:6443,https://10.240.0.12:6443 \\
  --cloud-provider= \\
  --cluster-dns=10.32.0.10 \\
  --cluster-domain=cluster.local \\
  --configure-cbr0=true \\
  --container-runtime=docker \\
  --docker=unix:///var/run/docker.sock \\
  --network-plugin=kubenet \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --reconcile-cidr=true \\
  --serialize-image-pulls=false \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kubelet",
      "sudo systemctl start kubelet",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<\"EOF\" | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \\
  --master=https://10.240.0.10:6443 \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --proxy-mode=iptables \\
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kube-proxy",
      "sudo systemctl start kube-proxy",
    ]
  }
}