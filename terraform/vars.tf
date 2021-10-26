variable "storageProxmox" {
    default = "k8s"
}

variable "proxmox_host" {
    default = "server1"
}

variable "nameCluster" {
    default = "k8s"
}

variable "masters" {
  type = map
  default = {
    "numInstancias"  = 1 
    "cores" = 4
    "ram" = 4096
    "disco" = "15G"
    "plantilla" = "ubuntu-template"
    "ssh_key" = "~/.ssh/id_rsa.pub"
    "ssh_key_ansible" = "~/.ssh/id_rsa"
    "user_host" = "ubuntu"
  }
}

variable "workers" {
  type = map
  default = {
    "numInstancias"  = 2 
    "cores" = 2
    "ram" = 2048
    "disco" = "15G"
    "plantilla" = "ubuntu-template"
    "ssh_key" = "~/.ssh/id_rsa.pub"
    "ssh_key_ansible" = "~/.ssh/id_rsa"
    "user_host" = "ubuntu"
  }
}

variable "red" {
  type = map
  default = {
    "subnet"  = "192.168.3.128/25"
    "mask" = "24"
    "gateway" = "192.168.3.1"    
  }
}