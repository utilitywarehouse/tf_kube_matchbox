terraform {
  required_version = ">= 0.13"
  required_providers {
    ignition = {
      source = "terraform-providers/ignition"
    }
    matchbox = {
      source = "poseidon/matchbox"
    }
  }
}
