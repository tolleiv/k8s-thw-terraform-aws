#
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-infrastructure-aws.md#user-content-kubernetes-public-address
#
resource "aws_elb" "kubernetes" {
  name = "kubernetes"
  subnets = [
    "${aws_subnet.main.id}"]

  listener {
    instance_port = 6443
    instance_protocol = "tcp"
    lb_port = 6443
    lb_protocol = "tcp"
  }
  security_groups = [
    "${aws_security_group.kubernetes.id}"]

  tags {
    Name = "kubernetes"
  }
}