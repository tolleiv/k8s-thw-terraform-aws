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
