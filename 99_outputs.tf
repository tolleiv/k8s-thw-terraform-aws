

output "elb" {
  value = "${aws_elb.kubernetes.dns_name}"
}