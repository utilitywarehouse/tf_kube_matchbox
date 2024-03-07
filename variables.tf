variable "matchbox_http_endpoint" {
  type        = string
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "flatcar_kernel_address" {
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
    disk_type     = string
  })
  validation {
    condition     = contains(["sata", "nvme"], var.cfssl_instance.disk_type)
    error_message = "Cfssl instance must specify a disk type of either sata or nvme."
  }

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
  description = "List of mac addresses and disk type for each etcd member"

  type = list(object({
    mac_addresses = list(string)
    disk_type     = string
  }))

  validation {
    condition = alltrue([
      for e in var.etcd_members : contains(["sata", "nvme"], e.disk_type)
    ])
    error_message = "All etcd members must specify a disk type of either sata or nvme."
  }

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
  description = "List of mac addresses and disk type for each master node"

  type = list(object({
    mac_addresses = list(string)
    disk_type     = string
  }))

  validation {
    condition = alltrue([
      for m in var.master_instances : contains(["sata", "nvme"], m.disk_type)
    ])
    error_message = "All master instances must specify a disk type of either sata or nvme."
  }

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
    disk_type     = string
  }))

  validation {
    condition = alltrue([
      for w in var.worker_instances : contains(["sata", "nvme"], w.disk_type)
    ])
    error_message = "All workers must specify a disk type of either sata or nvme."
  }
}

variable "worker_proxmox_instances" {
  description = "A list of mac addresses for worker nodes deployed on proxmox"
  type        = list(string)
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

variable "worker_persistent_storage_patition" {
  description = "Whether to create a local disk partition for persistent storage on worker nodes"
  type        = bool
  default     = false
}

variable "worker_persistent_storage_mountpoint" {
  description = "Location for the local storage partition to be mounted"
  type        = string
  default     = "/var/lib/csi-local-hostpath"
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

variable "cfssl_local_patition_disk" {
  description = "Whether to create a local disk partition for storing cfssl data"
  type        = bool
  default     = false
}
