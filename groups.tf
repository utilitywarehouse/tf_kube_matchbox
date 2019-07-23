resource "matchbox_group" "cfssl" {
  name    = "cfssl"
  profile = matchbox_profile.cfssl.name

  selector = {
    mac = var.cfssl_mac_address
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

resource "matchbox_group" "etcd" {
  count   = var.etcd_instance_count
  name    = "etcd-${count.index}"
  profile = matchbox_profile.etcd[count.index].name

  selector = {
    mac = var.etcd_mac_addresses[count.index]
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

resource "matchbox_group" "master" {
  count   = var.masters_instance_count
  name    = "master-${count.index}"
  profile = matchbox_profile.master[count.index].name

  selector = {
    mac = null_resource.masters.*.triggers.mac_address[count.index]
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

resource "matchbox_group" "worker" {
  count   = var.workers_instance_count
  name    = "worker-${count.index}"
  profile = matchbox_profile.worker[count.index].name

  selector = {
    mac = null_resource.workers.*.triggers.mac_address[count.index]
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

resource "matchbox_group" "storage-node" {
  count   = var.storage_node_count
  name    = "storage-node-${count.index}"
  profile = matchbox_profile.storage-node[count.index].name

  selector = {
    mac = null_resource.storage-nodes.*.triggers.mac_address[count.index]
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
  }
}

