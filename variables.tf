variable "name" {
  default = "nat-instance"
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}

variable "nat_subnet_id" {}

variable "instance_type" {
  default = "t4g.micro"
}

variable "private_route_table_id" {}

variable "security_groups" {
  type = list(string)
}

variable "ami" {
  default = ""
}

variable "aws_iam_instance_profile" {}

variable "key_name" {}

variable "internet_access" {
  default = true
}

data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

data "aws_iam_instance_profile" "ssm" {
  name = var.aws_iam_instance_profile
}

data "aws_subnet" "nat" {
  id = local.nat_subnet_id
}

data "aws_region" "current" {}

locals {
  name                   = var.name
  vpc_id                 = data.aws_subnet.nat.vpc_id
  instance_type          = var.instance_type
  nat_subnet_id          = var.nat_subnet_id
  key_name               = var.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.ssm
  private_route_table_id = var.private_route_table_id
  security_groups        = var.security_groups
  az                     = data.aws_subnet.nat.availability_zone
  ami                    = var.ami == "" ? data.aws_ami.nat.id : var.ami
  internet_route         = var.internet_access == true ? 1 : 0
  tags                   = merge({ Name = local.name }, var.tags)
}