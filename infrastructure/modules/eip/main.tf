# ==============================================================================
# Module: EIP (Elastic IP)
# Purpose: Allocates and associates static public IP with Jenkins EC2 instance
# Commit: feat(eip): Provision elastic IP for Jenkins server
# ==============================================================================

# ------------------------------------------------------------------------------
# Elastic IP Allocation
# Allocates a static public IP address from AWS pool
# Commit: feat(eip): Allocate elastic IP for Jenkins instance
# ------------------------------------------------------------------------------
resource "aws_eip" "jenkins" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eip"
  })
}

# ------------------------------------------------------------------------------
# Elastic IP Association
# Associates the elastic IP with the Jenkins EC2 instance
# Commit: feat(eip): Associate elastic IP with Jenkins EC2 instance
# ------------------------------------------------------------------------------
resource "aws_eip_association" "jenkins" {
  instance_id   = var.instance_id
  allocation_id = aws_eip.jenkins.id
}