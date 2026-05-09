output "eip" {
  value = aws_eip.jenkins.public_ip
}

output "allocation_id" {
  value = aws_eip.jenkins.id
}