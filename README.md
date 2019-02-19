# tf_kube_matchbox

This terraform module creates configuration to launch a kubernetes cluster taht can be stored in a matchbox server. It's designed to synergise well with [tf_kube_ignition](https://github.com/utilitywarehouse/tf_kube_ignition).

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
module "cluster" {
  source                  = "github.com/utilitywarehouse/tf_kube_matchbox"
  matchbox_http_endpoint  = "http://matchbox.example.com:8080"
  dns_domain              = "example.com"
  cluster_subnet          = "10.88.0.0/24"
  ssh_address_range       = "10.91.0.0/24"
  cfssl_address           = "10.88.0.8"
  cfssl_mac_address       = "XX:XX:XX:XX:XX:XX"
  cfssl_ignition_systemd  = "${module.ignition.cfssl_ignition_systemd}"
  cfssl_ignition_files    = "${module.ignition.cfssl_ignition_files}"
  etcd_instance_count     = 1
  etcd_mac_addresses      = ["XX:XX:XX:XX:XX:XX"]
  etcd_subnet_cidr        = "10.88.0.32/29"
  etcd_ignition_systemd   = "${module.ignition.etcd_ignition_systemd}"
  etcd_ignition_files     = "${module.ignition.etcd_ignition_files}"
  masters_instance_count  = 1
  masters_instances       = ["XX:XX:XX:XX:XX:XX","nvme"]
  masters_subnet_cidr     = "10.88.0.64/29"
  master_ignition_systemd = "${module.ignition.master_ignition_systemd}"
  master_ignition_files   = "${module.ignition.master_ignition_files}"
  workers_instance_count  = 2
  workers_instances       = ["XX:XX:XX:XX:XX:XX,nvme", "XX:XX:XX:XX:XX:XX,sda"]
  workers_subnet_cidr     = "10.88.0.128/25"
  worker_ignition_systemd = "${module.ignition.worker_ignition_systemd}"
  worker_ignition_files   = "${module.ignition.worker_ignition_files}"
}
```
