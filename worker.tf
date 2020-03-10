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

// Firewall rules via iptables
data "ignition_file" "worker_iptables_rules" {
  filesystem = "root"
  path = "/var/lib/iptables/rules-save"
  mode = 420

  content {
    content = <<EOS
*filter
# Default Policies: Drop all incoming and forward attempts, allow outgoing
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Allow eveything on localhost
-A INPUT -i lo -j ACCEPT
# Allow all connections initiated by the host
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow ssh from jumpbox
-A INPUT -p tcp -m tcp -s "${var.ssh_address_range}" --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# Allow masters to talk to workers
-A INPUT -p tcp -m tcp -s "${var.masters_subnet_cidr}" -j ACCEPT
-A INPUT -p udp -m udp -s "${var.masters_subnet_cidr}" -j ACCEPT
-A INPUT -p ipip -s "${var.masters_subnet_cidr}" -j ACCEPT
# Allow nodes to talk
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" -j ACCEPT
-A INPUT -p udp -m udp -s "${var.nodes_subnet_cidr}" -j ACCEPT
-A INPUT -p ipip -s "${var.nodes_subnet_cidr}" -j ACCEPT
# Allow incoming ICMP for echo replies, unreachable destination messages, and time exceeded
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 0 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 3 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 11 -j ACCEPT
COMMIT
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
    [data.ignition_systemd_unit.iptables-rule-load.id],
    var.worker_ignition_systemd,
  )

  files = concat(
    [
      data.ignition_file.worker_hostname[count.index].id,
      data.ignition_file.worker_iptables_rules.id,
    ],
      var.worker_ignition_files,
  )
}
