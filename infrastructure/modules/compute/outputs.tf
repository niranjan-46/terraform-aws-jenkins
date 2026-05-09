output "instance_id" {
  value = aws_instance.jenkins.id
}

output "instance_type" {
  value = aws_instance.jenkins.instance_type
}

output "data_volume_id" {
  value = aws_ebs_volume.data.id
}

output "instance_profile" {
  value = aws_iam_instance_profile.ec2_profile.name
}