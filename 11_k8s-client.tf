
resource "null_resource" "provision-k8s-client" {
  depends_on = [
    "null_resource.provision-k8s-controller", "null_resource.kubernetes-cert"]

  triggers {
    instance_ips = "${aws_elb.kubernetes.id}"
  }

  provisioner "local-exec" {
    command = <<EOT
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca/ca.pem \
  --embed-certs=true \
  --server=https://${aws_elb.kubernetes.dns_name}:6443
kubectl config set-credentials admin --token CHANGETHIS
kubectl config set-context k8s-hard \
  --cluster=kubernetes-the-hard-way \
  --user=admin
kubectl config use-context k8s-hard
kubectl get componentstatuses
kubectl get nodes
    EOT
  }
}