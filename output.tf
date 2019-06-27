output "cfssl_dns_name" {
  value = local.cfssl_dns_name
}

output "etcd_dns_names" {
  value = null_resource.etcd_hostnames.*.triggers.name
}

output "master_dns_names" {
  value = null_resource.masters.*.triggers.name
}

output "worker_dns_names" {
  value = null_resource.workers.*.triggers.name
}
