output "cfssl_dns_name" {
  value = local.cfssl_dns_name
}

output "cfssl_data_volumeid" {
  value = "disk/by-partlabel/${var.cfssl-partlabel}"
}

output "etcd_data_volumeids" {
  value = [for e in var.etcd_members: "disk/by-partlabel/${var.etcd-partlabel}"]
}
