resource "matchbox_profile" "master" {
  count  = var.masters_instance_count
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

resource "null_resource" "masters" {
  count = var.masters_instance_count

  triggers = {
    name        = "master-${count.index}.${var.dns_domain}"
    mac_address = element(split(",", var.masters_instances[count.index]), 0)
    disk_type   = element(split(",", var.masters_instances[count.index]), 1)
  }
}

// Set a hostname
data "ignition_file" "master_hostname" {
  count      = var.masters_instance_count
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420

  content {
    content = <<EOS
${null_resource.masters.*.triggers.name[count.index]}
EOS

  }
}

// Get ignition config from the module
data "ignition_config" "master" {
  count = var.masters_instance_count

  disks = [
    null_resource.masters.*.triggers.disk_type[count.index] == "nvme" ? data.ignition_disk.devnvme.id : data.ignition_disk.devsda.id,
  ]

  filesystems = [
    data.ignition_filesystem.root.id,
  ]

  systemd = concat(
    var.master_ignition_systemd,
  )

  files = concat(
    [
      data.ignition_file.master_hostname[count.index].id,
    ],
    var.master_ignition_files,
  )

  directories = var.master_ignition_directories
}
