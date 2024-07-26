terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.92.0"
}

provider "yandex" {
 token     = "t1.9euelZrLkI6Lj5yQipzOlY-aj5TLme3rnpWakcibjpaPns2dmc-PjceQysrl8_dHB3ZK-e9CPAVc_d3z9wc2c0r570I8BVz9zef1656VmozJjc6djpPIlMmdkJKayZeW7_zN5_XrnpWazc_LlpuJkpCNlsuTmJXImovv_cXrnpWajMmNzp2Ok8iUyZ2QkprJl5Y.VJNQinK_feWmhh-SzIcP7p2TY5USGUqi25Fz5i5IqD5MfJPCCpaUgyyr_jUwtuhE88-TakmjuPyPaZ9BjibkAQ"
 cloud_id  = "b1gqkugmt2d5nr2n85l9"
 folder_id = "b1g3acl1dihgarklvhm3"
 zone      = "ru-central1-a"
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
