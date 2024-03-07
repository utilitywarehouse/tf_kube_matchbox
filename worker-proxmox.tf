resource "matchbox_profile" "worker_proxmox" {
  count  = length(var.worker_proxmox_instances)
  name   = "worker-proxmox-${count.index}"
  kernel = var.flatcar_kernel_address
  initrd = var.flatcar_initrd_addresses
  args = [
    "initrd=flatcar_production_pxe_image.cpio.gz",
    "ignition.config.url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
    "flatcar.first_boot=yes",
  ]

  raw_ignition = data.ignition_config.worker_proxmox[count.index].rendered
}

resource "matchbox_group" "worker_proxmox" {
  count = length(var.worker_proxmox_instances)
  name  = "worker-proxmox-${count.index}"

  profile = matchbox_profile.worker_proxmox[count.index].name

  selector = {
    mac = var.worker_proxmox_instances[count.index]
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

# Set a hostname
data "ignition_file" "worker_proxmox_hostname" {
  count = length(var.worker_proxmox_instances)
  path  = "/etc/hostname"
  mode  = 420

  content {
    content = <<EOS
worker-proxmox-${count.index}.${var.dns_domain}
EOS
  }
}

data "ignition_config" "worker_proxmox" {
  count = length(var.worker_proxmox_instances)

  systemd = var.worker_ignition_systemd

  files = concat(
    var.worker_ignition_files,
    [
      data.ignition_file.worker_proxmox_hostname[count.index].rendered,
    ]
  )

  directories = var.worker_ignition_directories
}
