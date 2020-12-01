resource "matchbox_profile" "etcd" {
  count  = length(var.etcd_members)
  name   = "etcd-${count.index}"
  kernel = var.flatcar_kerner_address
  initrd = var.flatcar_initrd_addresses
  args = [
    "initrd=flatcar_production_pxe_image.cpio.gz",
    "ignition.config.url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
    "flatcar.first_boot=yes",
    "root=LABEL=ROOT",
    "console=tty0",
    "console=ttyS0",
  ]

  raw_ignition = data.ignition_config.etcd[count.index].rendered
}

# construct a list of group maps where each group has the following format:
# group {
#   mac = <mac_address>
#   profile =<matchbox_profile>
# }
locals {
  etcd_groups = flatten([
    for index, _ in var.etcd_members : [
      for _, mac_address in var.etcd_members[index].mac_addresses : {
        mac     = mac_address
        profile = matchbox_profile.etcd[index]
      }
    ]
  ])
}

resource "matchbox_group" "etcd" {
  count = length(local.etcd_groups)
  name  = "etcd-${count.index}"

  profile = local.etcd_groups[count.index].profile.name

  selector = {
    mac = local.etcd_groups[count.index].mac
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

variable "etcd-partlabel" {
  default = "ETCD"
}

data "ignition_disk" "etcd-sda" {
  device     = "/dev/sda"
  wipe_table = true

  partition {
    size   = 50011340 // Approx 25 gigs
    label  = var.etcd-partlabel
    number = 1
  }

  partition {
    label  = "ROOT"
    number = 2
  }
}

data "ignition_filesystem" "root-etcd" {
  name = "ROOT"

  mount {
    device          = "/dev/disk/by-partlabel/ROOT"
    format          = "ext4"
    wipe_filesystem = true
    label           = "ROOT"
  }
}

data "ignition_filesystem" "etcd" {
  name = "etcd"

  mount {
    device = "/dev/disk/by-partlabel/${var.etcd-partlabel}"
    format = "ext4"
  }
}

# Set a hostname
data "ignition_file" "etcd_hostname" {
  count      = length(var.etcd_members)
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420

  content {
    content = <<EOS
etcd-${count.index}.${var.dns_domain}
EOS
  }
}

# Create the bond interface for each member
# use first available mac address to override
data "ignition_networkd_unit" "bond0_etcd" {
  count = length(var.etcd_members)

  name    = "20-bond0.network"
  content = <<EOS
[Match]
Name=bond0

[Link]
MTUBytes=9000
MACAddress=${var.etcd_members[count.index].mac_addresses[0]}

[Network]
DHCP=yes
EOS
}

# Firewall rules via iptables
data "ignition_file" "etcd_iptables_rules" {
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
# Allow etcds to talk
-A INPUT -p tcp -m tcp -s "${var.etcd_subnet_cidr}" --dport 2379 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.etcd_subnet_cidr}" --dport 2380 -j ACCEPT
# Allow masters subnet to talk to etcds
-A INPUT -p tcp -m tcp -s "${var.masters_subnet_cidr}" --dport 2379 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.masters_subnet_cidr}" --dport 2380 -j ACCEPT
# Allow nodes subnet to talk to etcds for metrics
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" --dport 9100 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" --dport 9378 -j ACCEPT
# Allow nodes subnet to talk to fluent-bit exporter for metrics
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" --dport 8080 -j ACCEPT
# Allow docker default subnet to talk to etcds port 2379 for etcdctl-wrapper
-A INPUT -p tcp -m tcp -s 172.17.0.1/16 --dport 2379 -j ACCEPT
# Allow incoming ICMP for echo replies, unreachable destination messages, and time exceeded
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 0 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 3 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 8 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 11 -j ACCEPT
COMMIT
EOS

  }
}

data "ignition_config" "etcd" {
  count = length(var.etcd_members)

  disks = [
    data.ignition_disk.etcd-sda.rendered,
  ]

  networkd = [
    data.ignition_networkd_unit.bond_net_eno.rendered,
    data.ignition_networkd_unit.bond_netdev.rendered,
    data.ignition_networkd_unit.bond0_etcd[count.index].rendered,
  ]

  filesystems = [
    data.ignition_filesystem.root-etcd.rendered,
    data.ignition_filesystem.etcd.rendered,
  ]

  systemd = concat(
    [data.ignition_systemd_unit.iptables-rule-load.rendered],
    var.etcd_ignition_systemd[count.index],
  )

  files = concat(
    [
      data.ignition_file.etcd_hostname[count.index].rendered,
      data.ignition_file.etcd_iptables_rules.rendered,
    ],
    var.etcd_ignition_files[count.index],
  )

  directories = var.etcd_ignition_directories[count.index]
}
