#
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-dns-addon.md
#
resource "null_resource" "provision-k8s-dns-addon" {
  depends_on = [
    "null_resource.provision-k8s-client"]

  triggers {
    instance_ips = "${aws_elb.kubernetes.id}"
  }

  provisioner "local-exec" {
    command = <<EOT
kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/services/kubedns.yaml
kubectl --namespace=kube-system get svc
kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/deployments/kubedns.yaml
kubectl --namespace=kube-system get pods
    EOT
  }
}