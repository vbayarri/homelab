resource "proxmox_lxc" "uptime_kuma" {
  target_node  = var.virtual_environment_node_name
  vmid         = 220
  hostname     = "uptimekuma"
  tags         = "terraform"
  ostemplate   = var.alpine_template_name
  unprivileged = true
  start        = true
  onboot       = true
  
  # Recursos definidos
  cores  = 2
  memory = 2048
  swap   = 2048

  ssh_public_keys = var.ssh_public_key

  features {
    nesting = true
    keyctl  = false
  }

  rootfs {
    storage = var.datastore_id
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.1.22/24"
    gw     = "192.168.1.1"
  }

  provisioner "local-exec" {
    # Usamos pct exec para ejecutar comandos dentro del LXC desde el host Proxmox
    command = <<EOT
      ssh ${var.proxmox_user}@${var.proxmox_ip} "pct exec ${self.vmid} -- apk add openssh"
      ssh ${var.proxmox_user}@${var.proxmox_ip} "pct exec ${self.vmid} -- rc-update add sshd"
      ssh ${var.proxmox_user}@${var.proxmox_ip} "pct exec ${self.vmid} -- /etc/init.d/sshd start"
    EOT
  }

}
