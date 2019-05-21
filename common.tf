// Default boot disk for machines that do not need partitions (masters, workers)
data "ignition_disk" "devnvme" {
  device     = "/dev/nvme0n1"
  wipe_table = true

  partition {
    size   = 100022680 // Approx 50 gigs
    label  = "ROOT"
    number = 1
  }

  partition {
    label  = "CEPH"
    number = 2
  }
}

// Default boot disk for machines that do not need partitions (masters, workers)
data "ignition_disk" "devsda" {
  device     = "/dev/sda"
  wipe_table = true

  partition {
    size   = 100022680 // Approx 50 gigs
    label  = "ROOT"
    number = 1
  }

  partition {
    label  = "CEPH"
    number = 2
  }
}

data "ignition_filesystem" "root" {
  name = "ROOT"

  mount {
    device          = "/dev/disk/by-partlabel/ROOT"
    format          = "ext4"
    wipe_filesystem = true
    label           = "ROOT"
  }
}

data "ignition_filesystem" "ceph" {
  name = "CEPH"

  mount {
    device = "/dev/disk/by-partlabel/CEPH"
    format = "ext4"
  }
}

data "template_file" "ceph-disk-mounter" {
  template = "${file("${path.module}/resources/disk-mounter.service")}"

  vars {
    script_path = "/opt/bin/format-and-mount"
    volume_id   = "disk/by-partlabel/CEPH"
    filesystem  = "ext4"
    user        = "ceph"
    group       = "ceph"
    mountpoint  = "/var/lib/ceph"
  }
}

data "ignition_systemd_unit" "ceph-disk-mounter" {
  name    = "disk-mounter.service"
  content = "${data.template_file.ceph-disk-mounter.rendered}"
}

data "ignition_file" "format-and-mount" {
  mode       = 0755
  filesystem = "root"
  path       = "/opt/bin/format-and-mount"

  content {
    content = "${file("${path.module}/resources/format-and-mount")}"
  }
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
