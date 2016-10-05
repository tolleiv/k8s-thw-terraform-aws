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
  domain_name_servers = ["AmazonProvidedDNS"]
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
  cidr_blocks = ["${var.vpc_cidr}"]
  security_group_id = "${aws_security_group.kubernetes.id}"
}

resource "aws_security_group_rule" "ssh_anywhere" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kubernetes.id}"
}

resource "aws_security_group_rule" "alt_https_anywhere" {
  type = "ingress"
  from_port = 6443
  to_port = 6443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kubernetes.id}"
}

resource "aws_elb" "kubernetes" {
  name = "kubernetes"
  subnets = ["${aws_subnet.main.id}"]

  listener {
    instance_port = 6443
    instance_protocol = "tcp"
    lb_port = 6443
    lb_protocol = "tcp"
  }
  security_groups = ["${aws_security_group.kubernetes.id}"]

  tags {
    Name = "kubernetes"
  }
}