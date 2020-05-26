resource "matchbox_profile" "storage-node" {
  count  = var.storage_node_count
  name   = "storage-node-${count.index}"
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

  raw_ignition = data.ignition_config.storage-node[count.index].rendered
}

variable "storage-node-partlabel" {
  default = "STORAGE_DEVICE"
}

data "ignition_disk" "devnvme-storage-node" {
  device     = "/dev/nvme0n1"
  wipe_table = true

  partition {
    size   = 100022680 // Approx 50 gigs
    label  = "ROOT"
    number = 1
  }

  partition {
    label  = var.storage-node-partlabel
    number = 2
  }
}

data "ignition_disk" "devsda-storage-node" {
  device     = "/dev/sda"
  wipe_table = true

  partition {
    size   = 100022680 // Approx 50 gigs
    label  = "ROOT"
    number = 1
  }

  partition {
    label  = var.storage-node-partlabel
    number = 2
  }
}

data "ignition_filesystem" "storage-device" {
  name = "STORAGE_DEVICE"

  mount {
    device = "/dev/disk/by-partlabel/${var.storage-node-partlabel}"
    format = "ext4"
  }
}

resource "null_resource" "storage-nodes" {
  count = var.storage_node_count

  triggers = {
    name        = "storage-node-${count.index}.${var.dns_domain}"
    mac_address = element(split(",", var.storage_nodes[count.index]), 0)
    disk_type   = element(split(",", var.storage_nodes[count.index]), 1)
  }
}

// Set a hostname
data "ignition_file" "storage_node_hostname" {
  count      = var.storage_node_count
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420

  content {
    content = <<EOS
${null_resource.storage-nodes.*.triggers.name[count.index]}
EOS

  }
}

data "ignition_config" "storage-node" {
  count = var.storage_node_count

  disks = [
    null_resource.storage-nodes.*.triggers.disk_type[count.index] == "nvme" ? data.ignition_disk.devnvme-storage-node.id : data.ignition_disk.devsda-storage-node.id,
  ]

  filesystems = [
    data.ignition_filesystem.root.id,
    data.ignition_filesystem.storage-device.id,
  ]

  systemd = concat(
    var.storage_node_ignition_systemd,
  )

  files = concat(
    [
      data.ignition_file.storage_node_hostname[count.index].id,
    ],
    var.storage_node_ignition_files,
  )

  directories = var.storage_node_ignition_directories
}
