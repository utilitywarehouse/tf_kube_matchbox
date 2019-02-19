resource "matchbox_profile" "cfssl" {
  name   = "cfssl"
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

  raw_ignition = "${data.ignition_config.cfssl.rendered}"
}

data "ignition_disk" "devnvme-cfssl" {
  device     = "/dev/nvme0n1"
  wipe_table = true

  partition {
    size   = 12502835 // Approx 5 gigs
    label  = "CFSSL"
    number = 1
  }

  partition {
    label  = "ROOT"
    number = 2
  }
}

data "ignition_filesystem" "root-cfssl" {
  name = "ROOT"

  mount {
    device          = "/dev/disk/by-partlabel/ROOT"
    wipe_filesystem = true
    format          = "ext4"
    label           = "ROOT"
  }
}

data "ignition_filesystem" "cfssl" {
  name = "cfssl"

  mount {
    device = "/dev/disk/by-partlabel/CFSSL"
    format = "ext4"
  }
}

// Set a hostname
locals {
  cfssl_dns_name = "cfssl.${var.dns_domain}"
}

data "ignition_file" "cfssl_hostname" {
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = "0644"

  content {
    content = <<EOS
${local.cfssl_dns_name}
EOS
  }
}

// Firewall rules via iptables
data "ignition_file" "cfssl_iptables_rules" {
  filesystem = "root"
  path       = "/var/lib/iptables/rules-save"
  mode       = "0644"

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
# Allow workers subnet to talk to etcds for metrics
-A INPUT -p tcp -m tcp -s "${var.workers_subnet_cidr}" --dport 8888 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.workers_subnet_cidr}" --dport 8889 -j ACCEPT
# Allow workers subnet to talk to node exporter
-A INPUT -p tcp -m tcp -s "${var.workers_subnet_cidr}" --dport 9100 -j ACCEPT
# Allow incoming ICMP for echo replies, unreachable destination messages, and time exceeded
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 0 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 3 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 11 -j ACCEPT
COMMIT
EOS
  }
}

// Get ignition config from the module
data "ignition_config" "cfssl" {
  disks = [
    "${data.ignition_disk.devnvme-cfssl.id}",
  ]

  filesystems = [
    "${data.ignition_filesystem.root-cfssl.id}",
    "${data.ignition_filesystem.cfssl.id}",
  ]

  systemd = ["${concat(
	    list(
          data.ignition_systemd_unit.iptables-rule-load.id,
			),
			var.cfssl_ignition_systemd,
	)}"]

  files = ["${concat(
	    list(
          data.ignition_file.cfssl_hostname.id,
          data.ignition_file.cfssl_iptables_rules.id,
			),
      var.cfssl_ignition_files,
  )}"]
}
