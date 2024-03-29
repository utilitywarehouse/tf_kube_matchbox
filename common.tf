// Default boot disk for machines that do not need partitions (masters, workers)
data "ignition_disk" "devnvme" {
  device     = "/dev/nvme0n1"
  wipe_table = true

  partition {
    label  = "ROOT"
    number = 1
  }
}

// Default boot disk for machines that do not need partitions (masters, workers)
data "ignition_disk" "devsda" {
  device     = "/dev/sda"
  wipe_table = true

  partition {
    label  = "ROOT"
    number = 1
  }
}

data "ignition_filesystem" "root" {
  device          = "/dev/disk/by-partlabel/ROOT"
  format          = "ext4"
  wipe_filesystem = true
  label           = "ROOT"
}

data "ignition_systemd_unit" "iptables-rule-load" {
  name = "iptables-rule-load.service"

  content = <<EOS
[Unit]
Description=Loads presaved iptables rules from /var/lib/iptables/rules-save
[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables-restore /var/lib/iptables/rules-save
[Install]
WantedBy=multi-user.target
EOS

}

# Common Network config
# Bond network interfaces eno*
data "ignition_file" "bond_net_eno" {
  path = "/etc/systemd/network/00-eno.network"
  mode = 420

  content {
    content = <<EOS
[Match]
Name=eno*

[Link]
MTUBytes=9000

[Network]
Bond=bond0
EOS
  }
}

# bond0 device
data "ignition_file" "bond_netdev" {
  path = "/etc/systemd/network/10-bond0.netdev"
  mode = 420

  content {
    content = <<EOS
[NetDev]
Name=bond0
Kind=bond

[Bond]
Mode=802.3ad
EOS
  }
}
