# Define required providers
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

variable "stack_name" {
  type    = string
  default = "demo-vm-node"
}

variable "image_name" {
  type    = string
  default = "Debian 12 bookworm"
}

variable "flavor_name" {
  type    = string
  default = "a1-ram2-disk20-perf1"
}

variable "ports" {
  type    = list(any)
  default = [80, 8000, 8080, 443]
}

resource "openstack_compute_keypair_v2" "keypair" {
  name = "${var.stack_name}_mykeypair"
  provisioner "local-exec" {
    command = "echo '${self.private_key}' > sshkey; chmod 600 sshkey; echo '${self.public_key}' > sshkey.pub"
  }
}

resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = "sec_${var.stack_name}"
  description = "sec group for ${var.stack_name}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "ipv6-icmp"
  remote_ip_prefix  = "::/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "::/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "other_ports" {
  count             = length(var.ports)
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = var.ports[count.index]
  port_range_max    = var.ports[count.index]
  remote_ip_prefix  = "::/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}


data "openstack_networking_network_v2" "network" {
  name = "ext-v6only1"
}

resource "openstack_networking_port_v2" "port" {
  name               = "${var.stack_name}_port"
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = [openstack_networking_secgroup_v2.secgroup.id]
  dns_name           = var.stack_name
}

data "openstack_images_image_v2" "image" {
  name        = var.image_name
  most_recent = true
}

resource "openstack_blockstorage_volume_v3" "volume" {
  name     = "${var.stack_name}_volume"
  size     = 5
  image_id = data.openstack_images_image_v2.image.id
}

resource "openstack_compute_instance_v2" "basic" {
  name        = var.stack_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.keypair.name

  user_data = base64encode((templatefile("files/userdata.yaml", {
    files = merge({
        "server_js" = base64gzip(file("files/server.js")),
        "systemd_unit" = base64gzip(file("files/nodejs_server.service"))
    })
  })))

  network {
    port = openstack_networking_port_v2.port.id
  }

  block_device {
    uuid             = openstack_blockstorage_volume_v3.volume.id
    source_type      = "volume"
    destination_type = "volume"
  }

  connection {
    host        = self.access_ip_v6
    type        = "ssh"
    user        = "debian"
    private_key = openstack_compute_keypair_v2.keypair.private_key
    agent       = false
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline     = ["cloud-init status --wait"]
  }
}

locals {
    instance_ip = openstack_networking_port_v2.port.all_fixed_ips[0]
}

output "instance" {
  value = local.instance_ip
}

output "command" {
  value = <<COMMAND
ssh-keyscan ${local.instance_ip} >> ~/.ssh/known_hosts
SSH_AUTH_SOCK= ssh -i ./sshkey debian@${local.instance_ip}
    COMMAND
}
