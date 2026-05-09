# Resource Naming Convention - Final Review

## Environment Isolation

| Environment | VPC CIDR | VPC Name | S3 State Bucket | DynamoDB Table |
|-------------|----------|-----------|-----------------|----------------|
| **Dev** | 10.0.0.0/16 | `jenkins-dev-vpc` | `jenkins-dev-terraform-state` | `jenkins-dev-state-lock` |
| **Staging** | 10.1.0.0/16 | `jenkins-staging-vpc` | `jenkins-staging-terraform-state` | `jenkins-staging-state-lock` |
| **Prod** | 10.2.0.0/16 | `jenkins-prod-vpc` | `jenkins-prod-terraform-state` | `jenkins-prod-state-lock` |

---

## All Resources - Final Naming Review

### DEV Environment (10.0.0.0/16)

| Resource Type | Resource Name | Identifier |
|---------------|---------------|------------|
| VPC | jenkins-dev-vpc | vpc-xxxxxxxx |
| Public Subnet | jenkins-dev-public-subnet-1a | subnet-xxxxxxxx |
| Private Subnet | jenkins-dev-private-subnet-1a | subnet-xxxxxxxx |
| Internet Gateway | jenkins-dev-igw | igw-xxxxxxxx |
| NAT Gateway | jenkins-dev-nat-gw | nat-xxxxxxxx |
| NAT EIP | jenkins-dev-nat-eip | eip-xxxxxxxx |
| Public Route Table | jenkins-dev-public-rt | rtb-xxxxxxxx |
| Private Route Table | jenkins-dev-private-rt | rtb-xxxxxxxx |
| Security Group | jenkins-dev-jenkins-sg | sg-xxxxxxxx |
| EC2 Instance | jenkins-dev-jenkins | i-xxxxxxxx |
| IAM Role | jenkins-dev-ec2-role | arn:aws:iam::xxxxx:role/jenkins-dev-ec2-role |
| IAM Profile | jenkins-dev-profile | jenkins-dev-profile |
| Root EBS | jenkins-dev-jenkins | vol-xxxxxxxx |
| Data EBS | jenkins-dev-jenkins-data | vol-xxxxxxxx |
| KMS Key | alias/jenkins-dev-ebs | key-xxxxxxxx |
| Elastic IP | jenkins-dev-eip | eip-xxxxxxxx |
| DLM Policy | jenkins-dev-daily-backup | policy-xxxxxxxx |
| S3 State | jenkins-dev-terraform-state | - |
| DynamoDB | jenkins-dev-state-lock | - |

---

### STAGING Environment (10.1.0.0/16)

| Resource Type | Resource Name | Identifier |
|---------------|---------------|------------|
| VPC | jenkins-staging-vpc | vpc-xxxxxxxx |
| Public Subnet | jenkins-staging-public-subnet-1a | subnet-xxxxxxxx |
| Private Subnet | jenkins-staging-private-subnet-1a | subnet-xxxxxxxx |
| Internet Gateway | jenkins-staging-igw | igw-xxxxxxxx |
| NAT Gateway | jenkins-staging-nat-gw | nat-xxxxxxxx |
| NAT EIP | jenkins-staging-nat-eip | eip-xxxxxxxx |
| Public Route Table | jenkins-staging-public-rt | rtb-xxxxxxxx |
| Private Route Table | jenkins-staging-private-rt | rtb-xxxxxxxx |
| Security Group | jenkins-staging-jenkins-sg | sg-xxxxxxxx |
| EC2 Instance | jenkins-staging-jenkins | i-xxxxxxxx |
| IAM Role | jenkins-staging-ec2-role | arn:aws:iam::xxxxx:role/jenkins-staging-ec2-role |
| IAM Profile | jenkins-staging-profile | jenkins-staging-profile |
| Root EBS | jenkins-staging-jenkins | vol-xxxxxxxx |
| Data EBS | jenkins-staging-jenkins-data | vol-xxxxxxxx |
| KMS Key | alias/jenkins-staging-ebs | key-xxxxxxxx |
| Elastic IP | jenkins-staging-eip | eip-xxxxxxxx |
| DLM Policy | jenkins-staging-daily-backup | policy-xxxxxxxx |
| S3 State | jenkins-staging-terraform-state | - |
| DynamoDB | jenkins-staging-state-lock | - |

---

### PROD Environment (10.2.0.0/16)

| Resource Type | Resource Name | Identifier |
|---------------|---------------|------------|
| VPC | jenkins-prod-vpc | vpc-xxxxxxxx |
| Public Subnet | jenkins-prod-public-subnet-1a | subnet-xxxxxxxx |
| Private Subnet | jenkins-prod-private-subnet-1a | subnet-xxxxxxxx |
| Internet Gateway | jenkins-prod-igw | igw-xxxxxxxx |
| NAT Gateway | jenkins-prod-nat-gw | nat-xxxxxxxx |
| NAT EIP | jenkins-prod-nat-eip | eip-xxxxxxxx |
| Public Route Table | jenkins-prod-public-rt | rtb-xxxxxxxx |
| Private Route Table | jenkins-prod-private-rt | rtb-xxxxxxxx |
| Security Group | jenkins-prod-jenkins-sg | sg-xxxxxxxx |
| EC2 Instance | jenkins-prod-jenkins | i-xxxxxxxx |
| IAM Role | jenkins-prod-ec2-role | arn:aws:iam::xxxxx:role/jenkins-prod-ec2-role |
| IAM Profile | jenkins-prod-profile | jenkins-prod-profile |
| Root EBS | jenkins-prod-jenkins | vol-xxxxxxxx |
| Data EBS | jenkins-prod-jenkins-data | vol-xxxxxxxx |
| KMS Key | alias/jenkins-prod-ebs | key-xxxxxxxx |
| Elastic IP | jenkins-prod-eip | eip-xxxxxxxx |
| DLM Policy | jenkins-prod-daily-backup | policy-xxxxxxxx |
| S3 State | jenkins-prod-terraform-state | - |
| DynamoDB | jenkins-prod-state-lock | - |

---

## Naming Convention Pattern

```
{project_name}-{environment}-{resource_type}-{identifier}

Examples:
- jenkins-dev-vpc
- jenkins-staging-subnet-1a
- jenkins-prod-jenkins-data
```

## Tagging Standard

All resources include:
```hcl
tags = {
  Environment = "dev|staging|prod"
  Project     = "jenkins"
  ManagedBy   = "Terraform"
  Owner       = "DevOps Team"
}
```

## Verification Checklist

- [x] Each environment has separate VPC (different CIDR)
- [x] VPC naming follows pattern: `jenkins-{env}-vpc`
- [x] Subnets follow pattern: `jenkins-{env}-{public|private}-subnet-1a`
- [x] Security groups follow pattern: `jenkins-{env}-jenkins-sg`
- [x] EC2 instances follow pattern: `jenkins-{env}-jenkins`
- [x] EBS volumes follow pattern: `jenkins-{env}-jenkins-data`
- [x] IAM roles follow pattern: `jenkins-{env}-ec2-role`
- [x] EIPs follow pattern: `jenkins-{env}-eip`
- [x] DLM policies follow pattern: `jenkins-{env}-daily-backup`
- [x] S3 buckets follow pattern: `jenkins-{env}-terraform-state`
- [x] DynamoDB tables follow pattern: `jenkins-{env}-state-lock`
- [x] All resources have consistent tags