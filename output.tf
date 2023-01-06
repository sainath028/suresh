
output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = aws_instance.Jenkins.*.public_ip
}

output "Elastic_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = aws_eip.eip.*.Elastic_ip
}