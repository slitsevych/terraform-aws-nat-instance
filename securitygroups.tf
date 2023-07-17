locals {
  egress_all = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
  }]

  ingress_self = [{ rule = "all-all" }]

  ingress_internal = [
    {
      rule        = "all-all"
      description = "Allow internal connections"
      cidr_blocks = data.aws_vpc.vpc.cidr_block
  }]
}

module "security_group_nat" {
  count = length(var.security_groups) == 0 ? 1 : 0

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${var.name}-nat-instance-sg"
  description = "NAT Instance security group"
  vpc_id      = data.aws_subnet.nat_single.vpc_id

  use_name_prefix = false

  ingress_with_cidr_blocks = local.ingress_internal
  ingress_with_self        = local.ingress_self
  egress_with_cidr_blocks  = local.egress_all

  tags = merge(
    tomap({ "Name" = "${var.name}-nat-instance-sg" }),
    var.tags
  )
}