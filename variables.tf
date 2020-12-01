variable "matchbox_http_endpoint" {
  type        = string
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "flatcar_kerner_address" {
  type        = string
  description = "Location of the http endpoint that serves the kernel vmlinuz file"
  default     = "http://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz"
}

variable "flatcar_initrd_addresses" {
  type        = list(string)
  description = "List of http endpoint locations the serve the flatcar initrd assets"
  default = [
    "http://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz",
  ]
}

variable "dns_domain" {
  description = "The domain under which this cluster's DNS records are set (cluster-name.example.com)."
}

variable "cfssl_instance" {
  type = object({
    ip_address    = string
    mac_addresses = list(string)
  })
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

variable "etcd_members" {
  description = "List of mac addresses for each etcd member"

  type = list(object({
    mac_addresses = list(string)
  }))
}

variable "etcd_subnet_cidr" {
  description = "Address range for etcd members for iptables rules"
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

variable "master_instances" {
  description = "List of mac addresses for each master node"

  type = list(object({
    mac_addresses = list(string)
  }))
}

variable "masters_subnet_cidr" {
  description = "Address range for master nodes for iptables rules"
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

variable "worker_instances" {
  description = "List of mac addresses for each worker node"

  type = list(object({
    mac_addresses = list(string)
  }))
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
