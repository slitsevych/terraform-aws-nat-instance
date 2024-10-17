data "aws_subnet" "nat_all" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  id = each.value.subnet_id
}

resource "aws_network_interface" "nat" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  subnet_id         = each.value.subnet_id
  source_dest_check = false
  security_groups   = var.security_groups

  tags = merge(tomap({ "Name" = "eni-${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}" }), var.tags)
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

  tags = merge(tomap({ "Name" = "eip-${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}" }), var.tags)
}

resource "aws_launch_template" "nat_instance" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  name          = "${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}"
  image_id      = local.ami
  instance_type = var.instance_type

  tags = merge(tomap({ "Name" = "lt-${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}" }), var.tags)

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

  block_device_mappings {
    device_name = tolist(data.aws_ami.nat.block_device_mappings)[0].device_name

    ebs {
      volume_size = var.instance_volume_size
      volume_type = "gp3"
    }
  }

  disable_api_stop        = true
  disable_api_termination = true
  ebs_optimized           = true

  network_interfaces {
    device_index         = 0
    network_interface_id = aws_network_interface.nat[each.key].id
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.tftpl", { vpc_cidr = data.aws_vpc.vpc.cidr_block }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(tomap({ "Name" = "${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}" }), var.tags)
  }
  
  # lifecycle {
  #   ignore_changes = [user_data, image_id]
  # }
}

locals {
    autoscaling_group_tags = [
      {
        key                 = "Env"
        value               = var.environment
        propagate_at_launch = true
      },
      {
        key                 = "Team"
        value               = var.team_name
        propagate_at_launch = true
      },
      {
        key                 = "Terraform"
        value               = "true"
        propagate_at_launch = true
      }
    ]
}

resource "aws_autoscaling_group" "nat_instance" {
  for_each = { for idx, subnet in local.rtable_subnets_map : idx => subnet }

  name               = "${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}"
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  availability_zones = [data.aws_subnet.nat_all[each.key].availability_zone]

  launch_template {
    id      = aws_launch_template.nat_instance[each.key].id
    version = aws_launch_template.nat_instance[each.key].latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-${substr(data.aws_subnet.nat_all[each.key].availability_zone, -2, -1)}"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.autoscaling_group_tags
    content {
      key                 = tag.value.key
      propagate_at_launch = tag.value.propagate_at_launch
      value               = tag.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}