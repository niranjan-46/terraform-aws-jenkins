# ==============================================================================
# Module: Security
# Purpose: Creates security groups with ingress/egress rules for Jenkins server
# Commit: feat(security): Create Jenkins security group with required ports
# ==============================================================================

# ------------------------------------------------------------------------------
# Jenkins Security Group
# Main security group for Jenkins server with all required access rules
# Commit: feat(security): Provision security group for Jenkins instance
# ------------------------------------------------------------------------------
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins-sg"
  })
}

# ------------------------------------------------------------------------------
# Ingress Rule: HTTP (Port 80)
# Allows HTTP traffic for web access
# Commit: feat(security): Allow HTTP access from anywhere
# ------------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "http" {
  description       = "HTTP access"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins.id
}

# ------------------------------------------------------------------------------
# Ingress Rule: HTTPS (Port 443)
# Allows HTTPS traffic for secure web access
# Commit: feat(security): Allow HTTPS access from anywhere
# ------------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "https" {
  description       = "HTTPS access"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins.id
}

# ------------------------------------------------------------------------------
# Ingress Rule: Jenkins UI (Port 8080)
# Allows Jenkins web interface access
# Commit: feat(security): Allow Jenkins UI access on port 8080
# ------------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "jenkins_ui" {
  description       = "Jenkins UI"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins.id
}

# ------------------------------------------------------------------------------
# Ingress Rule: Jenkins Agent (Port 50000)
# Allows Jenkins agent communication for distributed builds
# Commit: feat(security): Allow Jenkins agent port for remoting
# ------------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "jenkins_agent" {
  description       = "Jenkins agent port"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 50000
  to_port           = 50000
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins.id
}

# ------------------------------------------------------------------------------
# Ingress Rule: SSH (Port 22)
# Allows SSH access for server administration
# Commit: feat(security): Allow SSH access for server management
# ------------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  description       = "SSH access"
  cidr_ipv4         = var.allowed_cidr_blocks[0]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins.id
}

# ------------------------------------------------------------------------------
# Egress Rule: Allow All
# Permits all outbound traffic for package updates and external APIs
# Commit: feat(security): Allow all outbound traffic for instance connectivity
# ------------------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "all_traffic" {
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  protocol          = "-1"
  security_group_id = aws_security_group.jenkins.id
}