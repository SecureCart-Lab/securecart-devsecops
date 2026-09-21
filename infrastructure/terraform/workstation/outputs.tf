output "instance_id" {
  value = aws_instance.workstation.id
}

output "public_ip" {
  value = aws_instance.workstation.public_ip
}

output "vpc_id" {
  value = aws_vpc.workstation.id
}

output "security_group_id" {
  value = aws_security_group.workstation.id
}

output "ssh_command" {
  value = "ssh -i /path/to/key.pem ubuntu@${aws_instance.workstation.public_ip}"
}
