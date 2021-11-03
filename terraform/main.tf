terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.8.0"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.proxmox["URL"]
  pm_api_token_id = var.proxmox["token_id"]
  pm_api_token_secret = var.proxmox["token_secret"]
  pm_tls_insecure = true
  pm_parallel = 3
}

resource "tls_private_key" "ssh_keys" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" { 
  filename = ".ssh/id_rsa"
  file_permission = "400"
  content = tls_private_key.ssh_keys.private_key_pem
}

resource "random_string" "random" {
  count =  "${var.HAProxy["numInstancias"] + var.masters["numInstancias"]  + var.workers["numInstancias"]}"
  length = 5  
  special = false
  number = false
}

resource "proxmox_vm_qemu" "k8s_HAProxy" {
  count = var.masters["numInstancias"] > 1 ? var.HAProxy["numInstancias"] : 0
  name = join("-", ["${var.nameCluster}", "hap", "${random_string.random[count.index].id}" ])  
  target_node = var.proxmox["target"]
  clone = var.HAProxy["plantilla"]
  agent = 1
  os_type = "cloud-init"
  cores = var.HAProxy["cores"]
  sockets = 1
  cpu = "host"
  memory = var.HAProxy["ram"]
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot = 0
    size = var.HAProxy["disco"]
    type = "scsi"
    storage = var.storageProxmox
    iothread = 1
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }
 
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
    
  ipconfig0 = join("", ["ip=", "${cidrhost(var.red["subnet"], count.index )}", "/" ,"${var.red["mask"]}", ",gw=", "${var.red["gateway"]}"]) 
  sshkeys = tls_private_key.ssh_keys.public_key_openssh
}

resource "proxmox_vm_qemu" "k8s_master" {
  count = var.masters["numInstancias"]  
  name = join("-", ["${var.nameCluster}", "mst", "${random_string.random[ var.HAProxy["numInstancias"] + count.index ].id}" ])  
  target_node = var.proxmox["target"]
  clone = var.masters["plantilla"]
  agent = 1
  os_type = "cloud-init"
  cores = var.masters["cores"]
  sockets = 1
  cpu = "host"
  memory = var.masters["ram"]
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot = 0
    size = var.masters["disco"]
    type = "scsi"
    storage = var.storageProxmox
    iothread = 1
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }
 
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
    
  ipconfig0 = join("", ["ip=", "${cidrhost(var.red["subnet"], var.HAProxy["numInstancias"] + count.index )}", "/" ,"${var.red["mask"]}", ",gw=", "${var.red["gateway"]}"]) 
  sshkeys = tls_private_key.ssh_keys.public_key_openssh
}

resource "proxmox_vm_qemu" "k8s_worker" {
  count = var.workers["numInstancias"]
  name = join("-", ["${var.nameCluster}", "wrk", "${random_string.random[ var.HAProxy["numInstancias"] + var.masters["numInstancias"] + count.index ].id}"])    
  target_node = var.proxmox["target"]
  clone = var.workers["plantilla"]
  agent = 1
  os_type = "cloud-init"
  cores = var.workers["cores"]
  sockets = 1
  cpu = "host"
  memory = var.workers["ram"]
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot = 0
    size = var.workers["disco"]
    type = "scsi"
    storage = var.storageProxmox
    iothread = 1
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }
 
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
    
  ipconfig0 = join("", ["ip=", "${cidrhost(var.red["subnet"], var.HAProxy["numInstancias"] + var.masters["numInstancias"] + count.index )}", "/" ,"${var.red["mask"]}", ",gw=", "${var.red["gateway"]}"]) 
  sshkeys = tls_private_key.ssh_keys.public_key_openssh
  
}

data "template_file" "k8s_host" {
  template = file("./templates/k8s.tpl")
  vars = {
    k8s_haproxy_ip = "${join("\n", [for instance in proxmox_vm_qemu.k8s_HAProxy : join("", [instance.default_ipv4_address, " ansible_ssh_private_key_file=", "../terraform/.ssh/id_rsa", " ansible_user=", var.HAProxy["user_host"]])])}"
    k8s_master_ip = "${join("\n", [for instance in proxmox_vm_qemu.k8s_master : join("", [instance.default_ipv4_address, " ansible_ssh_private_key_file=", "../terraform/.ssh/id_rsa", " ansible_user=", var.masters["user_host"]])])}"
    k8s_node_ip   = "${join("\n", [for instance in proxmox_vm_qemu.k8s_worker : join("", [instance.default_ipv4_address, " ansible_ssh_private_key_file=", "../terraform/.ssh/id_rsa", " ansible_user=", var.workers["user_host"]])])}"
  }
}

resource "local_file" "k8s_file" {
  content  = data.template_file.k8s_host.rendered
  filename = "../ansible/inventory/hosts.ini"
}

data "template_file" "HAProxy" {
  count = var.masters["numInstancias"] > 1 ? 1 : 0
  template = file("./templates/haproxy.tpl")
  vars = {
    k8s_haproxy_ip_bind = "${proxmox_vm_qemu.k8s_HAProxy[count.index].default_ipv4_address}"     
    k8s_master_ip_bind = "${join("\n", [for instance in proxmox_vm_qemu.k8s_master : join("", ["server ", instance.name ," " ,instance.default_ipv4_address, ":6443 check fall 3 rise 2" ])])}"    
  }
}

resource "local_file" "haproxy_file" {
  count = var.masters["numInstancias"] > 1 ? 1 : 0
  content  = data.template_file.HAProxy[count.index].rendered
  filename = "../ansible/roles/haproxy/templates/haproxy.j2"
}


output "HAProxy-IPS" {
  value = ["${proxmox_vm_qemu.k8s_HAProxy.*.default_ipv4_address}"]
}

output "Master-IPS" {
  value = ["${proxmox_vm_qemu.k8s_master.*.default_ipv4_address}"]
}

output "worker-IPS" {
  value = ["${proxmox_vm_qemu.k8s_worker.*.default_ipv4_address}"]
}