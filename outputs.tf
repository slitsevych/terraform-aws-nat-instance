output "eip" {
  value = { for k, v in aws_eip.public_ip : k => v.public_ip }
}

output "network_interface_id" {
  value = { for k, v in aws_network_interface.nat : k => v.id }
}

output "elastic_ips" {
  value = { for k, v in aws_eip.public_ip : k => v.public_ip }
}

output "eni_ids" {
  value = { for k, v in aws_network_interface.nat : k => v.id }
}

output "route_ids" {
  value = { for k, v in aws_route.internet : k => v.id }
}

output "launch_template_ids" {
  value = { for k, v in aws_launch_template.nat_instance : k => v.id }
}

output "autoscaling_group_ids" {
  value = { for k, v in aws_autoscaling_group.nat_instance : k => v.id }
}

output "azs" {
  value = { for k, v in data.aws_subnet.nat_all : k => v.availability_zone }
}