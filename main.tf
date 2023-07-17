data "aws_subnet" "nat_all" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  id = each.value.subnet_id
}

resource "aws_network_interface" "nat" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  subnet_id         = each.value.subnet_id
  source_dest_check = false
  security_groups   = var.security_groups
  tags              = local.tags
}

resource "aws_route" "internet" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  route_table_id         = each.value.route_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat[each.key].id
}


resource "aws_eip" "public_ip" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  domain            = "vpc"
  network_interface = aws_network_interface.nat[each.key].id
  tags              = local.tags
}

resource "aws_launch_template" "nat_instance" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  name_prefix   = "${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}"
  image_id      = local.ami
  instance_type = var.instance_type
  tags          = local.tags

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  iam_instance_profile {
    name = local.iam_instance_profile
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    device_index         = 0
    network_interface_id = aws_network_interface.nat[each.key].id
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.tftpl", { vpc_cidr = data.aws_vpc.vpc.cidr_block }))

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
}

resource "aws_autoscaling_group" "nat_instance" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  name_prefix        = "${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}"
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  availability_zones = [data.aws_subnet.nat_all[each.key].availability_zone]

  launch_template {
    id      = aws_launch_template.nat_instance[each.key].id
    version = aws_launch_template.nat_instance[each.key].latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}