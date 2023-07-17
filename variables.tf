variable "name" {
  type        = string
  description = "General name for resources"
  default     = "nat-instance"
}

variable "instance_type" {
  type        = string
  description = "NAT instance type (default to ARM-based)"
  default     = "t4g.nano"
}

variable "ami" {
  description = "AMI for nat instance"
  type        = string
  default     = ""
}

variable "aws_iam_instance_profile" {
  type        = string
  description = "Name of IAM instance profile to assign to EC2 instance"
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(any)
  default     = {}
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnets ids in which we will create NAT instances"
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "List of private route table IDs for which we will create NAT rules"
  default     = []
}

variable "security_groups" {
  type        = list(string)
  description = "List of security groups created outside of module to attach"
  default     = []
}

#####################

data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

data "aws_subnet" "nat_single" {
  id = element(var.public_subnet_ids, 0)
}

data "aws_vpc" "vpc" {
  id = data.aws_subnet.nat_single.vpc_id
}

data "aws_region" "current" {}

locals {
  ami                  = var.ami == "" ? data.aws_ami.nat.id : var.ami
  iam_instance_profile = var.aws_iam_instance_profile == "" ? aws_iam_instance_profile.ssm_profile[0].name : var.aws_iam_instance_profile

  # map of public subnets received in var.public_subnet_ids list
  public_subnets_map = [
    for key, subnet in var.public_subnet_ids : {
      subnet_id = subnet
    }
  ]

  # map of private route tables ids received in var.private_route_table_ids list
  private_rtables_map = [
    for key, route in var.private_route_table_ids : {
      route_id = route
    }
  ]

  equal_length = length(var.public_subnet_ids) != length(var.private_route_table_ids) ? min(length(var.private_route_table_ids), length(var.public_subnet_ids)) : length(var.public_subnet_ids)


  # final construct where we merge route table ids and subnets in one map blocks to use in for_each loops
  rtable_subnets_map = [
    for route, subnet in zipmap(slice(local.private_rtables_map.*.route_id, 0, local.equal_length), slice(local.public_subnets_map.*.subnet_id, 0, local.equal_length)) :
    {
      route_id  = route
      subnet_id = subnet
    }
  ]
}
