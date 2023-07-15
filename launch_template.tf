resource "aws_network_interface" "nat" {
  subnet_id         = local.nat_subnet_id
  source_dest_check = false
  security_groups   = local.security_groups
  tags              = local.tags
}

resource "aws_eip" "public_ip" {
  vpc               = true
  network_interface = aws_network_interface.nat.id
  tags              = local.tags
}

resource "aws_launch_template" "nat_instance" {
  name_prefix   = local.name
  image_id      = local.ami
  instance_type = local.instance_type
  key_name      = local.key_name
  tags          = local.tags

  iam_instance_profile {
    name = local.iam_instance_profile
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    device_index         = 0
    network_interface_id = aws_network_interface.nat.id
  }

  user_data = file("scripts/provision.sh")

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
}
