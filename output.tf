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

output "storage_node_dns_names" {
  value = null_resource.storage-nodes.*.triggers.name
}

output "cfssl_data_volumeid" {
  value = "disk/by-partlabel/${var.cfssl-partlabel}"
}

output "etcd_data_volumeids" {
  value = null_resource.etcd_partlabels.*.triggers.label
}

output "storage_node_volumeid" {
  value = "disk/by-partlabel/${var.storage-node-partlabel}"
}
