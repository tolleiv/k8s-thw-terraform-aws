#
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-infrastructure-aws.md#user-content-chosing-an-image
#
resource "null_resource" "ssh-key" {
  provisioner "local-exec" {
    command = <<EOT
test -d ssh || mkdir ssh
test -f ssh/kubernetes_the_hard_way || ssh-keygen -t rsa -C "kubernetes_the_hard_way" -P '' -f ssh/kubernetes_the_hard_way
EOT
  }
}

resource "aws_key_pair" "kubernetes" {
  key_name = "kubernetes-key"
  public_key = "${file("ssh/kubernetes_the_hard_way.pub")}"
  depends_on = ["null_resource.ssh-key"]
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
  count = "${var.instance_controller_count}"
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
}

resource "aws_instance" "worker" {
  count = "${var.instance_worker_count}"
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
}