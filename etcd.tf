resource "matchbox_profile" "etcd" {
  count  = "${var.etcd_instance_count}"
  name   = "etcd-${count.index}"
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

  raw_ignition = "${data.ignition_config.etcd.*.rendered[count.index]}"
}

data "ignition_disk" "devnvme-etcd" {
  device     = "/dev/nvme0n1"
  wipe_table = true

  partition {
    size   = 50011340 // Approx 25 gigs
    label  = "ETCD"
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
    device = "/dev/disk/by-partlabel/ETCD"
    format = "ext4"
  }
}

resource "null_resource" "etcd_hostnames" {
  count = "${var.etcd_instance_count}"

  triggers {
    name = "etcd-${count.index}.${var.dns_domain}"
  }
}

// Set a hostname
data "ignition_file" "etcd_hostname" {
  count      = "${var.etcd_instance_count}"
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = "0644"

  content {
    content = <<EOS
${null_resource.etcd_hostnames.*.triggers.name[count.index]}
EOS
  }
}

// Firewall rules via iptables
data "ignition_file" "etcd_iptables_rules" {
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
# Allow etcds to talk
-A INPUT -p tcp -m tcp -s "${var.etcd_subnet_cidr}" --dport 2379 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.etcd_subnet_cidr}" --dport 2380 -j ACCEPT
# Allow masters subnet to talk to etcds
-A INPUT -p tcp -m tcp -s "${var.masters_subnet_cidr}" --dport 2379 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.masters_subnet_cidr}" --dport 2380 -j ACCEPT
# Allow workers subnet to talk to etcds for metrics
-A INPUT -p tcp -m tcp -s "${var.workers_subnet_cidr}" --dport 9100 -j ACCEPT
-A INPUT -p tcp -m tcp -s "${var.workers_subnet_cidr}" --dport 9378 -j ACCEPT
# Allow docker default subnet to talk to etcds port 2379 for etcdctl-wrapper
-A INPUT -p tcp -m tcp -s 172.17.0.1/16 --dport 2379 -j ACCEPT
# Allow incoming ICMP for echo replies, unreachable destination messages, and time exceeded
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 0 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 3 -j ACCEPT
-A INPUT -p icmp -m icmp -s "${var.cluster_subnet}" --icmp-type 11 -j ACCEPT
COMMIT
EOS
  }
}

// Get ignition config from the module
data "ignition_config" "etcd" {
  count = "${var.etcd_instance_count}"

  disks = [
    "${data.ignition_disk.devnvme-etcd.id}",
  ]

  filesystems = [
    "${data.ignition_filesystem.root-etcd.id}",
    "${data.ignition_filesystem.etcd.id}",
  ]

  systemd = ["${concat(
	    list(
          data.ignition_systemd_unit.iptables-rule-load.id,
			),
			var.etcd_ignition_systemd[count.index],
	)}"]

  files = ["${concat(
	    list(
          data.ignition_file.etcd_hostname.*.id[count.index],
          data.ignition_file.etcd_iptables_rules.id,
			),
      var.etcd_ignition_files[count.index],
  )}"]
}
