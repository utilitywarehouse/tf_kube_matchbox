output "etcd_data_volumeids" {
  value = [for e in var.etcd_members: "disk/by-partlabel/${var.etcd-partlabel}"]
}
