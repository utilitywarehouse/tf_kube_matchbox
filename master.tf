resource "matchbox_profile" "master" {
  count  = length(var.master_instances)
  name   = "master-${count.index}"
  kernel = "http://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz"

  initrd = [
    "http://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz",
  ]

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
    for index, profile in matchbox_profile.master : [
      for _, mac_address in var.master_instances[index].mac_addresses : {
        mac     = mac_address
        profile = profile
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
MACAddress=${var.master_instances[count.index].mac_addresses[0]}

[Network]
DHCP=yes
EOS
}

data "ignition_config" "master" {
  count = length(var.master_instances)

  disks = [
    data.ignition_disk.devsda.id,
  ]

  networkd = [
    data.ignition_networkd_unit.bond_net_eno.id,
    data.ignition_networkd_unit.bond_netdev.id,
    data.ignition_networkd_unit.bond0_master[count.index].id,
  ]

  filesystems = [
    data.ignition_filesystem.root.id,
  ]

  systemd = concat(
    var.master_ignition_systemd,
  )

  files = concat(
    var.master_ignition_files,
    [
      data.ignition_file.master_hostname[count.index].id,
    ]
  )

  directories = var.master_ignition_directories
}
