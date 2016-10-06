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