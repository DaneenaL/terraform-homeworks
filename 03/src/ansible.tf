resource "local_file" "hosts_templatefile" {
  content = templatefile("${path.module}/${var.inventory_template}", {
    webservers = yandex_compute_instance.web
    databases  = values(yandex_compute_instance.db)
    storage    = [yandex_compute_instance.storage]
  })
  filename = "${abspath(path.module)}/${var.inventory_file}"
}

resource "null_resource" "ansible_provision" {
  triggers = {
    inventory = local_file.hosts_templatefile.content
  }

  provisioner "local-exec" {
    command    = "ansible-playbook -i ${abspath(path.module)}/${var.inventory_file} -u ${var.vm_user} ${abspath(path.module)}/${var.playbook_file}"
    on_failure = continue
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
      ANSIBLE_TIMEOUT           = "10"
    }
  }
}
