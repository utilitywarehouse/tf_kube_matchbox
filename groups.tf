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

