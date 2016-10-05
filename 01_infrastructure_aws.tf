resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  instance_tenancy = "dedicated"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "kubernetes"
  }
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name = "eu-central-1.compute.internal"
  domain_name_servers = [
    "AmazonProvidedDNS"]
  tags {
    Name = "kubernetes"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
}

resource "aws_subnet" "main" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_subnet_cidr}"

  tags {
    Name = "kubernetes"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "kubernetes"
  }
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "kubernetes"
  }
}
resource "aws_route_table_association" "main" {
  subnet_id = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_security_group" "kubernetes" {
  name = "kubernetes"
  description = "Kubernetes security group"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "kubernetes"
  }
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

resource "aws_iam_role" "kubernetes" {
  name = "kubernetes"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {"Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com"}, "Action": "sts:AssumeRole"}
  ]
}
EOF
}

resource "aws_iam_role_policy" "kubernetes" {
  name = "kubernetes"
  role = "${aws_iam_role.kubernetes.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow", "Action": ["ec2:*"], "Resource": ["*"]},
    {"Effect": "Allow", "Action": ["elasticloadbalancing:*"], "Resource": ["*"]},
    {"Effect": "Allow", "Action": ["route53:*"], "Resource": ["*"]},
    {"Effect": "Allow", "Action": ["ecr:*"], "Resource": "*"}
  ]
}
EOF
}

resource "aws_iam_instance_profile" "kubernetes" {
  name = "kubernetes"
  roles = [
    "${aws_iam_role.kubernetes.name}"]
}

resource "aws_key_pair" "kubernetes" {
  key_name = "kubernetes-key"
  public_key = "${file("ssh/kubernetes_the_hard_way.pub")}"
}


data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04*"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "controller" {
  count = 3
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "m3.medium"
  tags {
    Name = "${format("controller%d", count.index)}"
  }
  source_dest_check = false
  associate_public_ip_address = true
  vpc_security_group_ids = [ "${aws_security_group.kubernetes.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.kubernetes.name}"
  key_name = "${aws_key_pair.kubernetes.key_name}"
  private_ip = "${lookup(var.instance_controller_ips, count.index)}"
  subnet_id = "${aws_subnet.main.id}"

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
resource "aws_instance" "worker" {
  count = 3
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "m3.medium"
  tags {
    Name = "${format("worker%d", count.index)}"
  }
  source_dest_check = false
  associate_public_ip_address = true
  vpc_security_group_ids = [ "${aws_security_group.kubernetes.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.kubernetes.name}"
  key_name = "${aws_key_pair.kubernetes.key_name}"
  private_ip = "${lookup(var.instance_worker_ips, count.index)}"
  subnet_id = "${aws_subnet.main.id}"

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