variable "storageProxmox" {
    default = "k8s"
}

variable "proxmox" {
    type = map
    default = {
      "target"        : "server1"
      "URL"           : "https://192.168.3.99:8006/api2/json"
      "token_id"      : "userTerraform@pam!token_id"
      "token_secret"  : "dc2339d9-401f-46c7-b89a-ec67711c1a29"
    }
}

variable "nameCluster" {
    default = "devK8S"
}

variable "HAProxy" {
  type = map
  default = {
    "numInstancias"  = 1
    "cores" = 1
    "ram" = 1024
    "disco" = "8G"
    "plantilla" = "ubuntu-template"
    "user_host" = "ubuntu"
  }
}

variable "masters" {
  type = map
  default = {
    "numInstancias"  = 1
    "cores" = 2
    "ram" = 4096
    "disco" = "15G"
    "plantilla" = "ubuntu-template"
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