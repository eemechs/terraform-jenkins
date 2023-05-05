# output "public_subnet_id" {
#   description = "ID of the public subnet"
#   value       = module.vpc.public_subnets[0].id
# }

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "sg_id" {
  description = "The ID of the security group"
  value       = aws_security_group.this.id
}

output "public_ip" {
  description = "The public IP address of the Jenkins server"
  value       = aws_eip.this.public_ip
}
