resource "matchbox_profile" "master" {
  count  = length(var.master_instances)
  name   = "master-${count.index}"
  kernel = var.flatcar_kernel_address
  initrd = var.flatcar_initrd_addresses
  args = [
    "initrd=flatcar_production_pxe_image.cpio.gz",
    "ignition.config.url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
    "flatcar.first_boot=yes",
    "root=LABEL=ROOT",
    "console=tty0",
    "console=ttyS0",
  ]

  raw_ignition = data.ignition_config.master[count.index].rendered
}

# construct a list of group maps where each group has the following format:
# group {
#   mac = <mac_address>
#   profile =<matchbox_profile>
# }
locals {
  master_groups = flatten([
    for index, _ in var.master_instances : [
      for _, mac_address in var.master_instances[index].mac_addresses : {
        mac     = mac_address
        profile = matchbox_profile.master[index]
      }
    ]
  ])
}

resource "matchbox_group" "master" {
  count = length(local.master_groups)
  name  = "master-${count.index}"

  profile = local.master_groups[count.index].profile.name

  selector = {
    mac = local.master_groups[count.index].mac
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

# Set a hostname
data "ignition_file" "master_hostname" {
  count      = length(var.master_instances)
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420

  content {
    content = <<EOS
master-${count.index}.${var.dns_domain}
EOS
  }
}

# Create the bond interface for each node
# use first available mac address to override
data "ignition_networkd_unit" "bond0_master" {
  count = length(var.master_instances)

  name    = "20-bond0.network"
  content = <<EOS
[Match]
Name=bond0

[Link]
MTUBytes=9000
MACAddress=${var.master_instances[count.index].mac_addresses[0]}

[Network]
DHCP=yes
EOS
}

data "ignition_config" "master" {
  count = length(var.master_instances)

  disks = [
    var.master_instances[count.index].disk_type == "nvme" ? data.ignition_disk.devnvme.rendered : data.ignition_disk.devsda.rendered,
  ]

  networkd = [
    data.ignition_networkd_unit.bond_net_eno.rendered,
    data.ignition_networkd_unit.bond_netdev.rendered,
    data.ignition_networkd_unit.bond0_master[count.index].rendered,
  ]

  filesystems = [
    data.ignition_filesystem.root.rendered,
  ]

  systemd = concat(
    var.master_ignition_systemd,
  )

  files = concat(
    var.master_ignition_files,
    [
      data.ignition_file.master_hostname[count.index].rendered,
    ]
  )

  directories = var.master_ignition_directories
}
