output "seoul_instance_ip" {
  description = "The public IP address of the Seoul validator instance."
  value       = data.aws_instance.seoul_validator_instance.public_ip
}

output "ohio_instance_ip" {
  description = "The public IP address of the Ohio validator instance."
  value       = data.aws_instance.ohio_validator_instance.public_ip
}