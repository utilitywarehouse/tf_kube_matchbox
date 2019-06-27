variable "matchbox_http_endpoint" {
  type        = string
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "dns_domain" {
  description = "The domain under which this cluster's DNS records are set (cluster-name.example.com)."
}

variable "cfssl_address" {
  description = "Ip address of cfssl server"
}

variable "cfssl_mac_address" {
  description = "Mac address of cfssl box"
}

variable "cfssl_ignition_systemd" {
  type        = list(string)
  description = "The systemd files to provide to the cfssl server."
}

variable "cfssl_ignition_files" {
  type        = list(string)
  description = "The ignition files to provide to the cfssl server."
}

variable "ssh_address_range" {
  description = "Address range from which to allow ssh"
}

variable "etcd_instance_count" {
  default     = 3
  description = "etcd members count"
}

variable "etcd_mac_addresses" {
  type        = list(string)
  description = "Mac address of etcd member nodes"
}

variable "etcd_subnet_cidr" {
  description = "Address range for etcd members"
}

variable "etcd_ignition_systemd" {
  type        = list(list(string))
  description = "The systemd files to provide to the etcd members."
}

variable "etcd_ignition_files" {
  type        = list(list(string))
  description = "The ignition files to provide to the etcd members."
}

variable "masters_instance_count" {
  default     = 3
  description = "master nodes count"
}

variable "masters_subnet_cidr" {
  description = "Address range for master nodes"
}

variable "masters_instances" {
  type        = list(string)
  description = "master instances list ['<mac_address>,<disk_type>']"
}

variable "master_ignition_systemd" {
  type        = list(string)
  description = "The systemd files to provide to master nodes."
}

variable "master_ignition_files" {
  type        = list(string)
  description = "The ignition files to provide to master nodes."
}

variable "workers_instance_count" {
  description = "worker nodes count"
}

variable "workers_instances" {
  type        = list(string)
  description = "worker instances list ['<mac_address>,<disk_type>']"
}

variable "workers_subnet_cidr" {
  description = "Address range for worker nodes"
}

variable "worker_ignition_systemd" {
  type        = list(string)
  description = "The systemd files to provide to worker nodes."
}

variable "worker_ignition_files" {
  type        = list(string)
  description = "The ignition files to provide to worker nodes."
}

variable "cluster_subnet" {
  description = "Cluster ip subnet"
}
