output "spot_instance_id" {
  description = "The ID of the instance launched by the spot request."
  value       = aws_spot_instance_request.validator_node.spot_instance_id
}