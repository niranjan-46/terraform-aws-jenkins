output "jenkins_server" {
  description = "Jenkins server details"
  value = {
    public_ip      = module.elastic_ip.eip
    instance_id    = module.jenkins_instance.instance_id
    instance_type  = module.jenkins_instance.instance_type
    jenkins_url    = "http://${module.elastic_ip.eip}:8080"
    ssh_command    = "ssh -i <key> ubuntu@${module.elastic_ip.eip}"
  }
}

output "network" {
  description = "Network details"
  value = {
    vpc_id       = module.network.vpc_id
    subnet_id    = module.network.public_subnet_id
    security_sg  = module.security.jenkins_sg_id
  }
}

output "storage" {
  description = "Storage details"
  value = {
    data_volume_id = module.jenkins_instance.data_volume_id
    backup_policy  = module.backup.dlm_policy_id
  }
}