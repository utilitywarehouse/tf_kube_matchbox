resource "matchbox_profile" "worker" {
  count  = length(var.worker_instances)
  name   = "worker-${count.index}"
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

  raw_ignition = data.ignition_config.worker[count.index].rendered
}

# construct a list of group maps where each group has the following format:
# group {
#   mac = <mac_address>
#   profile =<matchbox_profile>
# }
locals {
  worker_groups = flatten([
    for index, _ in var.worker_instances : [
      for _, mac_address in var.worker_instances[index].mac_addresses : {
        mac     = mac_address
        profile = matchbox_profile.worker[index]
      }
    ]
  ])
}

resource "matchbox_group" "worker" {
  count = length(local.worker_groups)
  name  = "worker-${count.index}"

  profile = local.worker_groups[count.index].profile.name

  selector = {
    mac = local.worker_groups[count.index].mac
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

# Set a hostname
data "ignition_file" "worker_hostname" {
  count = length(var.worker_instances)
  path  = "/etc/hostname"
  mode  = 420

  content {
    content = <<EOS
worker-${count.index}.${var.dns_domain}
EOS
  }
}

# Create the bond interface for each node
# use first available mac address to override
data "ignition_file" "bond0_worker" {
  count = length(var.worker_instances)

  path = "/etc/systemd/network/20-bond0.network"
  mode = 420

  content {
    content = <<EOS
[Match]
Name=bond0

[Link]
MTUBytes=9000
MACAddress=${var.worker_instances[count.index].mac_addresses[0]}

[Network]
DHCP=yes
EOS
  }
}

locals {
  worker_nvme_disk = var.worker_persistent_storage_patition ? data.ignition_disk.storage_worker_nvme.rendered : data.ignition_disk.devnvme.rendered
  worker_sata_disk = var.worker_persistent_storage_patition ? data.ignition_disk.storage_worker_sda.rendered : data.ignition_disk.devsda.rendered
}

data "ignition_config" "worker" {
  count = length(var.worker_instances)

  disks = [
    var.worker_instances[count.index].disk_type == "nvme" ? local.worker_nvme_disk : local.worker_sata_disk,
  ]

  filesystems = [
    data.ignition_filesystem.root.rendered,
    var.worker_persistent_storage_patition ? data.ignition_filesystem.storage.rendered : "",
  ]

  systemd = concat(
    var.worker_ignition_systemd,
    [
      var.worker_persistent_storage_patition ? data.ignition_systemd_unit.storage_disk_mounter.rendered : "",
    ]
  )

  files = concat(
    var.worker_ignition_files,
    [
      data.ignition_file.bond_net_eno.rendered,
      data.ignition_file.bond_netdev.rendered,
      data.ignition_file.bond0_worker[count.index].rendered,
      data.ignition_file.worker_hostname[count.index].rendered,
      var.worker_persistent_storage_patition ? data.ignition_file.format_and_mount.rendered : "",
    ]
  )

  directories = var.worker_ignition_directories
}
