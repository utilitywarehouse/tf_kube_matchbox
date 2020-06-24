# tf_kube_matchbox

This terraform module creates configuration to launch a kubernetes cluster that can be stored in a matchbox server. It's designed to synergise well with [tf_kube_ignition](https://github.com/utilitywarehouse/tf_kube_ignition).

## Input Variables

The input variables are documented in their description and it's best to refer to [variables.tf](variables.tf)

## Ouputs

- `cfssl_dns_name` - hostname of cfssl server
- `etcd_dns_names` - list of etcd nodes hostnames
- `master_dns_names` - list of master nodes hostnames
- `worker_dns_names` - list of worker nodes hostnames

## Usage

Below is an example of how you might use this terraform module:

```hcl
variable "cfssl_instance" {
  type = object({
    ip_address    = string
    mac_addresses = list(string)
  })

  default = {
    ip_address    = "10.88.0.8"
    mac_addresses = ["aa:bb:cc:dd:ee:ff", ]
  }
}

variable "etcd_members" {
  type = list(object({
    mac_addresses = list(string)
  }))

  default = [
    {
      mac_addresses = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
    },
    {
      mac_addresses = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
    },
  ]
}

variable "master_instances" {
  type = list(object({
    mac_addresses = list(string)
  }))

  default = [
    {
      mac_addresses = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
    },
  ]
}

variable "worker_instances" {
  type = list(object({
    mac_addresses = list(string)
  }))

  default = [
    {
      mac_addresses = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
    },
    {
      mac_addresses = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
    },
    {
      mac_addresses = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
    },
  ]
}


module "cluster" {
  source                  = "github.com/utilitywarehouse/tf_kube_matchbox"
  matchbox_http_endpoint  = "http://matchbox.example.com:8080"
  dns_domain              = "example.com"
  cluster_subnet          = "10.88.0.0/24"
  pod_network             = "10.6.0.0/16"
  ssh_address_range       = "10.91.0.0/24"
  cfssl_instance          = var.cfssl_instance
  cfssl_ignition_systemd  = "${module.ignition.cfssl_ignition_systemd}"
  cfssl_ignition_files    = "${module.ignition.cfssl_ignition_files}"
  etcd_members            = var.etcd_members
  etcd_subnet_cidr        = "10.88.0.32/29"
  etcd_ignition_systemd   = "${module.ignition.etcd_ignition_systemd}"
  etcd_ignition_files     = "${module.ignition.etcd_ignition_files}"
  master_instances        = var.master_instances
  masters_subnet_cidr     = "10.88.0.64/29"
  master_ignition_systemd = "${module.ignition.master_ignition_systemd}"
  master_ignition_files   = "${module.ignition.master_ignition_files}"
  nodes_subnet_cidr       = "10.88.0.128/25"
  worker_instances        = var.worker_instances
  worker_ignition_systemd = "${module.ignition.worker_ignition_systemd}"
  worker_ignition_files   = "${module.ignition.worker_ignition_files}"
}
```
