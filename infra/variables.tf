variable "aws_region" { default = "us-east-1" }
variable "environment" { default = "shopmicro" }
variable "key_name" { default = "terraform-key-pair" }
variable "admin_ip" { 
  description = "Your personal IP address (e.g., 102.89.x.x/32) to allow SSH. Satisfies 'No public SSH' requirement."
  type        = string
}