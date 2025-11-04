# Infrastructure Inventory

## Proxmox Hosts

### Physical Servers

| Hostname | IP Address | CPU | RAM | Storage | Role | Status |
|----------|------------|-----|-----|---------|------|--------|
| proxmox01 | TBD | TBD | TBD | TBD | Hypervisor | Active |

## Proxmox Host Prerequisites for Terraform

To allow Terraform to manage Proxmox resources, a specific one-time setup is required on the Proxmox host. This involves creating dedicated users for API and SSH access, and configuring permissions.

### 1. API Access Configuration

Terraform uses the Proxmox API for most operations. This requires an API-specific user and role.

**A. Create a Role for Terraform**
1.  Navigate to **Datacenter -> Roles** and create a new role (e.g., `TerraformProv`).
2.  Assign it the following comprehensive list of privileges:
    `Datastore.Allocate`, `Datastore.AllocateSpace`, `Datastore.AllocateTemplate`, `Datastore.Audit`, `Pool.Allocate`, `Sys.Audit`, `Sys.Console`, `Sys.Modify`, `VM.Allocate`, `VM.Audit`, `VM.Clone`, `VM.Config.CDROM`, `VM.Config.Cloudinit`, `VM.Config.CPU`, `VM.Config.Disk`, `VM.Config.HWType`, `VM.Config.Memory`, `VM.Config.Network`, `VM.Config.Options`, `VM.Migrate`, `VM.PowerMgmt`

**B. Create an API User**
1.  Navigate to **Datacenter -> Permissions -> Users** and create a new user (e.g., `terraform-prov@pve`).

**C. Assign Permissions**
1.  Navigate to **Datacenter -> Permissions** and add a new permission.
2.  **Path**: `/`
3.  **User**: `terraform-prov@pve`
4.  **Role**: `TerraformProv`
5.  Ensure **Propagate** is checked.

**D. Create API Token**
1.  Under the `terraform-prov@pve` user, go to the **API Tokens** tab and create a new token. Securely store the token ID and secret, as they will be used in Terraform variables.

### 2. SSH Access Configuration

Terraform requires a standard Linux user to connect via SSH for operations not covered by the API.

**A. Create a Linux User**
1.  Connect to the Proxmox host as `root`.
2.  Create a non-root user for Terraform to use:
    ```bash
    useradd -m -s /bin/bash terraform
    ```

**B. Set up SSH Key Authentication**
1.  From your local machine, copy your SSH public key to the new user on the Proxmox host:
    ```bash
    ssh-copy-id terraform@<proxmox-ip>
    ```
2.  If password authentication is disabled, manually add your public key to `/home/terraform/.ssh/authorized_keys`.
3.  Ensure permissions are correct on the Proxmox host:
    ```bash
    chown -R terraform:terraform /home/terraform/.ssh
    chmod 700 /home/terraform/.ssh
    chmod 600 /home/terraform/.ssh/authorized_keys
    ```

**C. Grant Passwordless Sudo Access**
For the `terraform` user to execute Proxmox utilities (`pvesm`, `qm`) that require elevated privileges, it needs passwordless `sudo` access. This is crucial for operations like creating custom disks.
1.  Connect to the Proxmox host as `root`.
2.  Edit the `sudoers` file using `visudo`:
    ```bash
    visudo
    ```
3.  Add the following line to the end of the file:
    ```
    terraform    ALL=(ALL) NOPASSWD: ALL
    ```

### 3. Storage Configuration

For Terraform to upload files like Cloud-Init configurations, the target storage must be configured correctly.

**A. Enable Snippets Content-Type**
1.  Navigate to **Datacenter -> Storage**.
2.  Select the storage used for snippets (e.g., `local`) and click **Edit**.
3.  In the **Content** dropdown, ensure `Snippets` is selected.

**B. Set Directory Permissions**
1.  Connect to the Proxmox host as `root`.
2.  Change the ownership of the snippets directory to the SSH user:
    ```bash
    chown terraform:terraform /var/lib/vz/snippets
    ```

### 4. Environment PATH Configuration

To resolve `command not found` errors for Proxmox utilities (like `pvesm`) during non-interactive SSH sessions, the user's `PATH` must be correctly set. The most reliable method is to force the `PATH` environment variable directly within the SSH authorized key, which requires a corresponding change in the SSH server configuration.

**Step 1: Enable User Environment in SSH Server**

The SSH server must be configured to allow keys to set environment variables. This is disabled by default.
1.  Connect to the Proxmox host as `root`.
2.  Edit the SSH server configuration file: `nano /etc/ssh/sshd_config`
3.  Find the `PermitUserEnvironment` directive, uncomment it if necessary, and set its value to `yes`:
    ```
    PermitUserEnvironment yes
    ```
4.  Save the file and restart the SSH service: `systemctl restart sshd`

**Step 2: Force PATH via SSH Authorized Key**

Once the server is configured, you can set the `PATH` for the key.
1.  On the Proxmox host, edit the SSH key in `/home/terraform/.ssh/authorized_keys`.
2.  Prepend the key with an `environment` directive. The final line should look like this (all on one line):
    ```
    environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ssh-rsa AAAA...
    ```

## Virtual Machines

### Production VMs

| Name | VMID | Host | vCPU | RAM | Disk | OS | IP | Purpose | Managed By |
|------|------|------|------|-----|------|----|----|---------|------------|
| minio | TBD | proxmox01 | 2 | 2GB | 20GB | Ubuntu 22.04 | TBD | S3 storage | Manual |

### Development VMs

| Name | VMID | Host | vCPU | RAM | Disk | OS | IP | Purpose | Managed By |
|------|------|------|------|-----|------|----|----|---------|------------|
| - | - | - | - | - | - | - | - | - | - |

## LXC Containers

### Production Containers

| Name | CTID | Host | CPU | RAM | Disk | OS | IP | Purpose | Managed By |
|------|------|------|-----|-----|------|----|----|---------|------------|
| - | - | - | - | - | - | - | - | - | - |

### Development Containers

| Name | CTID | Host | CPU | RAM | Disk | OS | IP | Purpose | Managed By |
|------|------|------|-----|-----|------|----|----|---------|------------|
| - | - | - | - | - | - | - | - | - | - |

## Storage

### Proxmox Storage

| Name | Type | Location | Size | Usage | Purpose |
|------|------|----------|------|-------|---------|
| local | dir | /var/lib/vz | TBD | TBD | ISO images, CT templates |
| local-lvm | lvmthin | /dev/pve/data | TBD | TBD | VM/CT disks |

### Minio Storage

| Bucket | Size | Purpose | Encryption | Versioning |
|--------|------|---------|------------|------------|
| terraform-state | TBD | Terraform state files | SSE-S3 | Enabled |

## Backup Infrastructure

### Proxmox Backup Server

| Location | Type | IP | Storage | Retention | Status |
|----------|------|----|---------|-----------| -------|
| Local | VM/Physical | TBD | TBD | TBD | TBD |
| Remote | Offsite | TBD | TBD | TBD | TBD |

### Backup Jobs

| Name | Source | Destination | Schedule | Retention | Last Run | Status |
|------|--------|-------------|----------|-----------|----------|--------|
| Daily VMs | All VMs | PBS Local | Daily 2:00 | 7 days | TBD | TBD |
| Weekly Full | All VMs | PBS Remote | Weekly Sun | 4 weeks | TBD | TBD |

## Resource Summary

### Total Resources

**Compute:**
- Physical CPUs: TBD
- Total RAM: TBD
- VMs: TBD
- Containers: TBD

**Storage:**
- Total Storage: TBD
- Used: TBD
- Available: TBD

**Network:**
- Network Interfaces: TBD
- Bridges: TBD
- VLANs: TBD

## Terraform-Managed Resources

### Resources Created by Terraform

| Resource Type | Name | File | Status |
|---------------|------|------|--------|
| - | - | - | - |

### Manually Managed Resources

Resources created outside of Terraform:

| Resource | Reason Not in Terraform | Migration Plan |
|----------|-------------------------|----------------|
| Minio VM | Bootstrap dependency | Import after setup |

## Hardware Details

### Server Specifications

**Proxmox Host 1:**
- Model: TBD
- CPU: TBD
- RAM: TBD
- Storage Controllers: TBD
- Network Cards: TBD
- IPMI/iLO: TBD

## Decommissioned Resources

| Name | Type | Decommission Date | Reason | Notes |
|------|------|-------------------|--------|-------|
| - | - | - | - | - |

## Notes

- Update this document when creating/destroying resources
- Mark Terraform-managed resources clearly
- Document any manual changes made outside Terraform
- Keep VMID/CTID allocations documented to avoid conflicts

## Terraform Configuration

### Provider Communication: API vs. SSH

The Terraform provider for Proxmox utilizes two distinct communication channels, requiring separate users and authentication methods:

1.  **API User (e.g., `terraform-prov@pve`)**: This user authenticates via an API token and is used for the vast majority of operations like creating, configuring, and deleting VMs and containers. The permissions for this user are managed through Proxmox's web interface under `Datacenter -> Permissions`.

2.  **SSH User (e.g., `terraform`)**: This is a standard Linux system user on the Proxmox host. It authenticates via an SSH key and is used for tasks that are not possible or efficient through the API, such as verifying Cloud-Init status, interacting with the guest agent, or performing certain file transfers. This user requires a valid home directory and `~/.ssh/authorized_keys` setup on the Proxmox host.

Both are essential for the provider's full functionality.

### Provider Settings

The Terraform provider for Proxmox requires specific configuration to work correctly in a homelab environment where self-signed certificates are common.

- **`insecure = true`**: This setting is added to the `provider "proxmox"` block to bypass TLS certificate verification. This is necessary to prevent `x509: certificate signed by unknown authority` errors when connecting to the Proxmox API, which uses a self-signed certificate by default.

### Permissions

A dedicated role should be created in Proxmox for the API user to limit its scope and enhance security.

**Role:** `TerraformProv`

**Privileges:**

The following privileges are required for the Terraform role to manage resources effectively:

```
Datastore.Allocate
Datastore.AllocateSpace
Datastore.AllocateTemplate
Datastore.Audit
Pool.Allocate
Sys.Audit
Sys.Console
Sys.Modify
VM.Allocate
VM.Audit
VM.Clone
VM.Config.CDROM
VM.Config.Cloudinit
VM.Config.CPU
VM.Config.Disk
VM.Config.HWType
VM.Config.Memory
VM.Config.Network
VM.Config.Options
VM.Migrate
VM.PowerMgmt
```

**Note:** The `Datastore.Allocate` permission is crucial. It allows Terraform to upload files, such as cloud-init configurations, to the Proxmox datastores. Without it, you will encounter a `403 Permission check failed` error when using resources like `proxmox_virtual_environment_file`.

### Storage Configuration for Cloud-Init

When using Terraform to create VMs with Cloud-Init, the `proxmox_virtual_environment_file` resource is used to upload the user data configuration. This resource requires a Proxmox storage that is configured to handle `Snippets`.

If you encounter an error like `the datastore "local" does not support content type "snippets"`, you must enable this content type for the specified storage.

**To fix:**
1.  In the Proxmox web UI, navigate to **Datacenter -> Storage**.
2.  Select the storage in question (e.g., `local`).
3.  Click **Edit**.
4.  In the **Content** dropdown, ensure that `Snippets` is selected in addition to any other content types.

