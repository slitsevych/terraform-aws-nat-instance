data "aws_route_table" "nat" {
  route_table_id = local.private_route_table_id
}

resource "aws_route" "internet" {
  count                  = local.internet_route
  route_table_id         = data.aws_route_table.nat.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat.id
}
