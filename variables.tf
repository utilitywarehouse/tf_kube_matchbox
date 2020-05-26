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

variable "cfssl_ignition_directories" {
  type        = list(string)
  description = "The ignition directories to provide to the cfssl server."
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

variable "etcd_ignition_directories" {
  type        = list(list(string))
  description = "The ignition directories to provide to the etcd members."
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

variable "master_ignition_directories" {
  type        = list(string)
  description = "The ignition directories to provide to master nodes."
}

variable "workers_instance_count" {
  description = "worker nodes count"
}

variable "workers_instances" {
  type        = list(string)
  description = "worker instances list ['<mac_address>,<disk_type>']"
}

variable "worker_ignition_systemd" {
  type        = list(string)
  description = "The systemd files to provide to worker nodes."
}

variable "worker_ignition_files" {
  type        = list(string)
  description = "The ignition files to provide to worker nodes."
}

variable "worker_ignition_directories" {
  type        = list(string)
  description = "The ignition directories to provide to worker nodes."
}

variable "storage_node_count" {
  description = "storage nodes count"
}

variable "storage_nodes" {
  type        = list(string)
  description = "storage nodes list ['<mac_address>,<disk_type>']"
}

variable "storage_node_ignition_systemd" {
  type        = list(string)
  description = "The systemd files to provide to storage nodes."
}

variable "storage_node_ignition_files" {
  type        = list(string)
  description = "The ignition files to provide to storage nodes."
}

variable "storage_node_ignition_directories" {
  type        = list(string)
  description = "The ignition directories to provide to storage nodes."
}

variable "nodes_subnet_cidr" {
  description = "Address range for kube slave nodes"
}

variable "cluster_subnet" {
  description = "Cluster ip subnet"
}

variable "cluster_internal_svc_subnet" {
  description = "Advertised ip subnet for internal services"
}

variable "pod_network" {
  description = "pod network cidr"
}
