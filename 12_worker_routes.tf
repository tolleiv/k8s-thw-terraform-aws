resource "aws_route" "workers" {
  route_table_id = "${aws_route_table.main.id}"
  count = "${var.instance_worker_count}"
  destination_cidr_block = "10.200.${count.index}.0/24"
  instance_id = "${element(aws_instance.worker.*.id, count.index)}"
}