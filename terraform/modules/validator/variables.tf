variable "availability_zone" {
  description = "The Availability Zone for the resources"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "The key pair name for the EC2 instance"
  type        = string
}

variable "my_ip_address" {
  description = "My public IP address for SSH access"
  type        = string
}
variable "instance_name_tag" {
  description = "The Name tag for the EC2 instance"
  type        = string
}
variable "security_group_name" {
  description = "The name of the security group to find or create"
  type        = string
}