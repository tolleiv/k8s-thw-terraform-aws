#
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-infrastructure-aws.md#firewall-rules
#
resource "aws_security_group" "kubernetes" {
  name = "kubernetes"
  description = "Kubernetes security group"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "kubernetes"
  }
}

resource "aws_security_group_rule" "all_outgoing" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = "${aws_security_group.kubernetes.id}"
}
resource "aws_security_group_rule" "all_internal" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = [
    "${var.vpc_cidr}"]
  security_group_id = "${aws_security_group.kubernetes.id}"
}

resource "aws_security_group_rule" "ssh_anywhere" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = "${aws_security_group.kubernetes.id}"
}

resource "aws_security_group_rule" "alt_https_anywhere" {
  type = "ingress"
  from_port = 6443
  to_port = 6443
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = "${aws_security_group.kubernetes.id}"
}