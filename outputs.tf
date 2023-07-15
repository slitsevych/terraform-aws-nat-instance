output "eip" {
  value = aws_eip.public_ip.public_ip
}

output "network_interface_id" {
  value = aws_network_interface.nat.id
}
