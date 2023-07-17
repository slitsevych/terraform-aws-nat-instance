# About

Terraform module to create NAT instances using launch templates & ASG.

The main objective is to create NAT instances per each route table supplied to the module.
Example: You have created 3 private subnets without NAT gateways using `terraform-aws-modules/vpc/aws` module and by default you'll have a list with th
3 route tables for each private subnet (per az). And you have 3 public subnets each in its own az.
With the help of this module, by passing list of public subnets and routes tabele ids, you'll get NAT instances for each route table which is effectively 1 NAT instance per AZ.

Module uses Ubuntu 22 AMI automatically configured to masquerade connections from your VPC cidr block.
By default module is using `arm64` architecture and `t4g.nano` instance type.
In terms of cost-effectiveness this allows to run 3 NAT instances for just $9 per month as total cost.

NOTES:

- if a length of `public_subnet_ids` is not equal to a length of `private_route_table_ids` (e.g, *1 route table and 3 public subnets*), then the module will automatically choose the `min` number among these two (*in our example that's 1*) and thus will create 1 NAT instance resources.

- Module does not add SSH keys to the instances and moreover its userdata script disables SSH daemon. Instead it assigns SSM role to the instance (which AMI already has `ssm-agent`) thus urging to use SSM Connect feature in case you need to get into the instance's shell. Module is able to either create a new IAM role with SSM permissions or process the existing role supplied as `var.aws_iam_instance_profile`

## Usage

```hcl
provider "aws" {
  region  = "us-east-2"
}

module "nat-instance" {
  source = "slitsevych/nat-instance/aws"

  public_subnet_ids        = module.vpc.public_subnets
  private_route_table_ids  = module.vpc.private_route_table_ids
  security_groups          = [module.security_group_nat.security_group_id]

  #name                     = "nat-instance" # default is "nat-instance"
  #instance_type            = "t4g.nano"     # default is "t4g.nano"
  #aws_iam_instance_profile = ""             # default is "" --> will be created by the module
  #ami                      = ""             # default is "" --> will be evaluated by the module
  
  tags = {
    Env = "common"
  }

  depends_on = [module.vpc] # created with terraform-aws-modules/vpc/aws; explicit dependency and thus this line is not necessary, provided just for information 
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.nat_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_eip.public_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.ssm_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ec2_ssm_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.nat_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_network_interface.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route.internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_ami.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.nat_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.nat_single](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | AMI for nat instance | `string` | `""` | no |
| <a name="input_aws_iam_instance_profile"></a> [aws\_iam\_instance\_profile](#input\_aws\_iam\_instance\_profile) | Name of IAM instance profile to assign to EC2 instance | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | NAT instance type (default to ARM-based) | `string` | `"t4g.nano"` | no |
| <a name="input_name"></a> [name](#input\_name) | General name for resources | `string` | `"nat-instance"` | no |
| <a name="input_private_route_table_ids"></a> [private\_route\_table\_ids](#input\_private\_route\_table\_ids) | List of private route table IDs for which we will create NAT rules | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnets ids in which we will create NAT instances | `list(string)` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of security groups created outside of module to attach | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_ids"></a> [autoscaling\_group\_ids](#output\_autoscaling\_group\_ids) | n/a |
| <a name="output_azs"></a> [azs](#output\_azs) | n/a |
| <a name="output_eip"></a> [eip](#output\_eip) | n/a |
| <a name="output_elastic_ips"></a> [elastic\_ips](#output\_elastic\_ips) | n/a |
| <a name="output_eni_ids"></a> [eni\_ids](#output\_eni\_ids) | n/a |
| <a name="output_launch_template_ids"></a> [launch\_template\_ids](#output\_launch\_template\_ids) | n/a |
| <a name="output_network_interface_id"></a> [network\_interface\_id](#output\_network\_interface\_id) | n/a |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | n/a |
<!-- END_TF_DOCS -->