variable "virtual_environment_endpoint" {
  type        = string
  description = "The endpoint URL for the Proxmox Virtual Environment (PVE) API (e.g., https://your-proxmox-host:8006/api2/json)."
}

variable "proxmox_ip" {
  type        = string
  description = "The IP address of the Proxmox server (e.g., 192.168.1.10)."
  sensitive   = true  
}

variable "proxmox_user" {
  type        = string
  description = "The username for SSH access to the Proxmox host."
  sensitive   = true  
}

variable "proxmox_api_token_id" {
  type        = string
  description = "The ID of the Proxmox API token (e.g., user@realm!tokenid)."
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "The secret of the Proxmox API token."
  sensitive   = true
}

variable "virtual_environment_node_name" {
  type        = string
  description = "The node name for the Proxmox Virtual Environment API (commonly 'pve')."
  default     = "pve"
}

variable "datastore_id" {
  type        = string
  description = "The ID of the datastore where VM disks will be stored (e.g., 'local-lvm' or 'cephfs')."
  default     = "local-lvm"
}

variable "alpine_template_name" {
  type        = string
  description = <<-EOT
  The filename of the Alpine Linux LXC template located in the Proxmox local storage.
  To update this:
  1. SSH into the Proxmox host.
  2. Find the latest template with: pveam available | grep alpine
  3. Download the chosen template with: pveam download local <template-filename>
  4. Update the value of this variable (e.g., in a terraform.tfvars file) to the new filename.
  EOT
  default     = "local:vztmpl/alpine-3.23-default_20260116_amd64.tar.xz"
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to be injected into the root user of the LXC containers for initial access. This allows passwordless SSH access to the created containers."
}
