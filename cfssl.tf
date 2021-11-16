resource "matchbox_profile" "cfssl" {
  name   = "cfssl"
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

  raw_ignition = data.ignition_config.cfssl.rendered
}

resource "matchbox_group" "cfssl" {
  count   = length(var.cfssl_instance.mac_addresses)
  name    = "cfssl-${count.index}"
  profile = matchbox_profile.cfssl.name

  selector = {
    mac = var.cfssl_instance.mac_addresses[count.index]
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

# Set a hostname
data "ignition_file" "cfssl_hostname" {
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420

  content {
    content = <<EOS
cfssl.${var.dns_domain}
EOS
  }
}

# Create the bond interface for each node
# use first available mac address to override
data "ignition_networkd_unit" "bond0_cfssl" {
  name    = "20-bond0.network"
  content = <<EOS
[Match]
Name=bond0

[Link]
MTUBytes=9000
MACAddress=${var.cfssl_instance.mac_addresses[0]}

[Network]
DHCP=yes
EOS
}

// Firewall rules via iptables
data "ignition_file" "cfssl_iptables_rules" {
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
# Allow etcds subnet to talk to cffsl
-A INPUT -p tcp -m tcp -s "${var.etcd_subnet_cidr}" --dport 8888 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.etcd_subnet_cidr}" --dport 8889 -j ACCEPT
# Allow masters subnet to talk to cffsl
-A INPUT -p tcp -m tcp -s "${var.masters_subnet_cidr}" --dport 8888 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.masters_subnet_cidr}" --dport 8889 -j ACCEPT
# Allow nodes subnet to talk to etcds for metrics
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" --dport 8888 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" --dport 8889 -j ACCEPT
# Allow workers subnet to talk to node exporter
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" --dport 9100 -j ACCEPT
# Allow nodes subnet to talk to fluent-bit exporter for metrics
-A INPUT -p tcp -m tcp -s "${var.nodes_subnet_cidr}" --dport 8080 -j ACCEPT
# Allow incoming ICMP for echo replies, unreachable destination messages, and time exceeded
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 0 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 3 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 8 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 11 -j ACCEPT
COMMIT
EOS

  }
}

// Get ignition config from the module
data "ignition_config" "cfssl" {
  disks = [
    var.cfssl_instance.disk_type == "nvme" ? data.ignition_disk.etcd_nvme.rendered : data.ignition_disk.etcd_sda.rendered,
  ]

  filesystems = [
    data.ignition_filesystem.root.rendered,
  ]

  networkd = [
    data.ignition_networkd_unit.bond_net_eno.rendered,
    data.ignition_networkd_unit.bond_netdev.rendered,
    data.ignition_networkd_unit.bond0_cfssl.rendered,
  ]

  systemd = concat(
    [data.ignition_systemd_unit.iptables-rule-load.rendered],
    var.cfssl_ignition_systemd,
  )

  files = concat(
    [
      data.ignition_file.cfssl_hostname.rendered,
      data.ignition_file.cfssl_iptables_rules.rendered,
    ],
    var.cfssl_ignition_files,
  )

  directories = var.cfssl_ignition_directories
}
