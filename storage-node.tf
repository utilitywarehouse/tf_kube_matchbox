resource "matchbox_profile" "storage-node" {
  count  = var.storage_node_count
  name   = "storage-node-${count.index}"
  kernel = "http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz"

  initrd = [
    "http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz",
  ]

  args = [
    "initrd=coreos_production_pxe_image.cpio.gz",
    "coreos.config.url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
    "coreos.first_boot=yes",
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

// Bond interfaces
data "ignition_networkd_unit" "storage_node_enp" {
  name    = "00-enp.network"
  content = <<EOS
[Match]
Name=enp*

[Network]
Bond=bond0
EOS
}

data "ignition_networkd_unit" "storage_node_bond_netdev" {
  name    = "10-bond0.netdev"
  content = <<EOS
[NetDev]
Name=bond0
Kind=bond

[Bond]
Mode=802.3ad
EOS
}

data "ignition_networkd_unit" "storage_node_bond0" {
  count   = var.storage_node_count
  name    = "20-bond0.network"
  content = <<EOS
[Match]
Name=bond0

[Link]
MACAddress=${null_resource.storage-nodes.*.triggers.mac_address[count.index]}

[Network]
DHCP=true
EOS

}

// Firewall rules via iptables
data "ignition_file" "storage_node_iptables_rules" {
  filesystem = "root"
  path       = "/var/lib/iptables/rules-save"
  mode       = 420

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

data "ignition_config" "storage-node" {
  count = var.storage_node_count

  disks = [
    null_resource.storage-nodes.*.triggers.disk_type[count.index] == "nvme" ? data.ignition_disk.devnvme-storage-node.id : data.ignition_disk.devsda-storage-node.id,
  ]

  filesystems = [
    data.ignition_filesystem.root.id,
    data.ignition_filesystem.storage-device.id,
  ]

  networkd = [
    data.ignition_networkd_unit.storage_node_enp.id,
    data.ignition_networkd_unit.storage_node_bond_netdev.id,
    data.ignition_networkd_unit.storage_node_bond0[count.index].id,
  ]

  systemd = concat(
    [data.ignition_systemd_unit.iptables-rule-load.id],
    var.storage_node_ignition_systemd,
  )

  files = concat(
    [
      data.ignition_file.storage_node_hostname[count.index].id,
      data.ignition_file.storage_node_iptables_rules.id,
    ],
    var.storage_node_ignition_files,
  )
}
