## About
Terraform module to create NAT instance.

## Usage

```hcl
module "nat-instance" {
  source               = "slitsevych/nat-instance/aws"
  version = "1.0.0"

  aws_key_name             = local.ssh_key # ssh key name
  nat_subnet_id            = element(module.vpc.public_subnets, 0)
  private_route_table_ids  = element(module.vpc.private_route_table_ids, 0) 
  aws_iam_instance_profile = "ec2-ssm-role" # must exist before, provide name

  security_groups = [
    module.security_group_internal.security_group_id, 
    module.security_group_nat.security_group_id
  ]

  depends_on = [module.vpc] # created with terraform-aws-modules/vpc/aws
}
```

## Outputs

