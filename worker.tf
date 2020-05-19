resource "matchbox_profile" "worker" {
  count  = var.workers_instance_count
  name   = "worker-${count.index}"
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

  raw_ignition = data.ignition_config.worker[count.index].rendered
}

resource "null_resource" "workers" {
  count = var.workers_instance_count

  triggers = {
    name        = "worker-${count.index}.${var.dns_domain}"
    mac_address = element(split(",", var.workers_instances[count.index]), 0)
    disk_type   = element(split(",", var.workers_instances[count.index]), 1)
  }
}

// Set a hostname
data "ignition_file" "worker_hostname" {
  count      = var.workers_instance_count
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420

  content {
    content = <<EOS
${null_resource.workers.*.triggers.name[count.index]}
EOS

  }
}

// Get ignition config from the module
data "ignition_config" "worker" {
  count = var.workers_instance_count

  disks = [
    null_resource.workers.*.triggers.disk_type[count.index] == "nvme" ? data.ignition_disk.devnvme.id : data.ignition_disk.devsda.id,
  ]

  filesystems = [
    data.ignition_filesystem.root.id,
  ]

  systemd = concat(
    var.worker_ignition_systemd,
  )

  files = concat(
    [
      data.ignition_file.worker_hostname[count.index].id,
    ],
    var.worker_ignition_files,
  )

  directories = [
    data.ignition_directory.journald.id
  ]
}
