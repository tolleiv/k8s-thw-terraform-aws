provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  instance_tenancy = "dedicated"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "kubernetes"
  }
}