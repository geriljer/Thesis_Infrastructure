terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.92.0"
}

provider "vault" {
  address = var.vault_host
  skip_tls_verify = true
  token = var.VAULT_TOKEN
}
# Fetch the Vault token stored within Vault
data "vault_generic_secret" "vault_token" {
  path = "secret/vault-token"
}

# Use the retrieved Vault token to reconfigure the Vault provider. alias is used to avoid an error message related to duplicate provider vault
provider "vault" {
  alias = "with_fetched_token"
  address = var.vault_host
  skip_tls_verify = true
  token   = data.vault_generic_secret.vault_token.data["vault_token"]
}

# Fetch the Yandex Cloud token from Vault
data "vault_generic_secret" "yc_token" {
  path = "secret/yandex-cloud-token"
}

provider "yandex" {
 token     = data.vault_generic_secret.yc_token.data["yc_token"]
 cloud_id  = var.cloud_id
 folder_id = var.folder_id
 zone      = var.zone
}

locals {
  vm_names = ["alev-node1-vm-1", "alev-node2-vm-2", "alev-node3-vm-3"]
}


resource "yandex_compute_instance" "vm" {
    count = length(local.vm_names)
    name = local.vm_names[count.index]
    resources {
        cores  = 2
        memory = 6
    }

    boot_disk {
        initialize_params {
            image_id = "fd80jfslq61mssea4ejn"
        }
    }

    network_interface {
        subnet_id = "e9bhi4aujiba622dj32s"
        nat       = true
    }

    scheduling_policy {
        preemptible = true
    }

    metadata = {
        user-data = file(var.new_user)
    }
  }

resource "local_file" "hosts_ini" {
     content = templatefile("hosts.tpl",
       {
         k8s-ip = [
            for instance in yandex_compute_instance.vm[*] :
            join(": ", [instance.network_interface.0.nat_ip_address])
            ]
       }
     )
     
     filename = "../ansible/host.ini"

  }

output "instance_output" {
  value = [
    for instance in yandex_compute_instance.vm[*] :
    join(": ", [instance.name, instance.hostname, instance.network_interface.0.ip_address, instance.network_interface.0.nat_ip_address])
  ]
}
