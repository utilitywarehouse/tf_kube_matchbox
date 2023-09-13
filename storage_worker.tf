variable "storage_partlabel" {
  default = "STORAGE"
}

data "ignition_disk" "storage_worker_sda" {
  device     = "/dev/sda"
  wipe_table = true

  partition {
    sizemib = 150000 // Approx 150 gigs
    label   = var.storage_partlabel
    number  = 1
  }

  partition {
    label  = "ROOT"
    number = 2
  }
}

data "ignition_disk" "storage_worker_nvme" {
  device     = "/dev/nvme0n1"
  wipe_table = true

  partition {
    sizemib = 150000 // Approx 150 gigs
    label   = var.storage_partlabel
    number  = 1
  }

  partition {
    label  = "ROOT"
    number = 2
  }
}

data "ignition_filesystem" "storage" {
  device          = "/dev/disk/by-partlabel/${var.storage_partlabel}"
  format          = "ext4"
}

data "ignition_file" "format_and_mount" {
  mode = 493
  path = "/opt/bin/format-and-mount"

  content {
    content = file("${path.module}/resources/format-and-mount")
  }
}

data "template_file" "storage_disk_mounter" {
  template = file("${path.module}/resources/disk-mounter.service")

  vars = {
    script_path = "/opt/bin/format-and-mount"
    volume_id   = "disk/by-partlabel/${var.storage_partlabel}"
    filesystem  = "ext4"
    user        = "root"
    group       = "root"
    mountpoint  = var.worker_persistent_storage_mountpoint
  }
}

data "ignition_systemd_unit" "storage_disk_mounter" {
  name    = "disk-mounter.service"
  content = data.template_file.storage_disk_mounter.rendered
}

