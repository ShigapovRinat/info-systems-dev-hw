
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# --- Создание сети ---
resource "yandex_vpc_network" "jmix_network" {
  name = "jmix-network"
}

# --- Создание подсети ---
resource "yandex_vpc_subnet" "jmix_subnet" {
  name           = "jmix-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.jmix_network.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

# --- Генерация SSH-ключей ---
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  filename = "${path.module}/id_rsa"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

resource "local_file" "public_key" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

# --- Создание ВМ ---
resource "yandex_compute_instance" "vm" {
  name        = "jmix-vm"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.yc_image_id
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.jmix_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ipiris:${tls_private_key.ssh_key.public_key_openssh}"
    user-data = file("${path.module}/install.sh")
  }
}
