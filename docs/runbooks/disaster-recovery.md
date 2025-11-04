# Disaster Recovery Runbook

## Overview

This runbook provides procedures for recovering from catastrophic failures affecting the homelab infrastructure.

## Disaster Scenarios

| Scenario | Impact | RTO | RPO | Complexity |
|----------|--------|-----|-----|------------|
| Single VM failure | Low | 15 min | 24 hours | Low |
| Proxmox host failure | Medium | 4 hours | 24 hours | Medium |
| Network failure | Medium | 2 hours | None | Medium |
| Storage failure | High | 8 hours | 24 hours | High |
| Complete site loss | Critical | 1-2 days | 7 days | High |
| Secrets compromise | Critical | 4 hours | None | Medium |

## Recovery Priority Matrix

### Tier 1: Critical (Restore First)
1. Network connectivity
2. Proxmox host
3. Minio (Terraform state)
4. DNS/DHCP (if applicable)

### Tier 2: Important (Restore Second)
5. Proxmox Backup Server
6. Monitoring services
7. Other infrastructure services

### Tier 3: Standard (Restore Third)
8. Application VMs
9. Development environments
10. Non-essential services

## DR Scenario: Complete Site Loss

### Prerequisites Checklist

Before disaster strikes, ensure you have:

- [ ] Remote PBS with recent backups
- [ ] GitHub repository with latest code
- [ ] Primary Yubikey accessible
- [ ] Backup Yubikey in safe location
- [ ] Password manager accessible
- [ ] This documentation printed or accessible externally
- [ ] Emergency contact list
- [ ] Network diagram
- [ ] IP addressing scheme documented

### Phase 1: Assessment (0-2 hours)

**Objectives:**
- Assess extent of damage
- Determine recovery strategy
- Acquire necessary resources

**Actions:**
1. Verify remote PBS accessibility
2. Check GitHub repository accessible
3. Locate backup Yubikey if primary lost
4. Inventory required hardware
5. Plan network topology
6. Notify stakeholders

**Deliverable:** Written recovery plan with timeline

### Phase 2: Infrastructure Rebuild (2-8 hours)

**Objective:** Restore basic infrastructure

#### Step 1: Acquire Hardware

**Required:**
- Server capable of running Proxmox VE
  - Minimum: 16GB RAM, 4 cores, 500GB storage
  - Network connectivity
- Network switch/router
- Yubikey (primary or backup)

#### Step 2: Install Proxmox VE

```bash
# Boot from Proxmox installer USB
# Follow installation wizard:
# - Set hostname: proxmox01 (or as documented)
# - Configure network: Use static IP from documentation
# - Set root password (store in password manager)
# - Configure timezone

# After installation, access web UI:
https://<proxmox-ip>:8006
```

#### Step 3: Configure Network

```bash
# SSH to Proxmox host
ssh root@<proxmox-ip>

# Configure bridges as documented
vim /etc/network/interfaces

# Example (adjust to your network.md):
auto vmbr0
iface vmbr0 inet static
    address <management-ip>/<mask>
    gateway <gateway-ip>
    bridge-ports eth0
    bridge-stp off
    bridge-fd 0

# Restart networking
systemctl restart networking
```

#### Step 4: Configure Remote PBS Access

```bash
# In Proxmox UI: Datacenter > Storage > Add > Proxmox Backup Server

# Or via CLI:
pvesm add pbs <storage-name> \
  --server <remote-pbs-ip> \
  --datastore <datastore-name> \
  --username <pbs-user>@pbs \
  --password <pbs-password>

# Verify access
pvesm status
```

### Phase 3: Restore Critical Services (8-12 hours)

#### Step 1: Restore Minio VM

**Priority:** Critical (Terraform state dependency)

```bash
# List available backups
pvesm list <pbs-storage>

# Find Minio backup
# Look for: vm-<minio-vmid>-<date>

# Restore Minio VM
qmrestore <pbs-storage>:backup/vm-<minio-vmid>-<date> <new-vmid>

# Configure VM network if needed
qm set <vmid> -ipconfig0 ip=<minio-ip>/24,gw=<gateway>

# Start VM
qm start <vmid>

# Wait for boot (check console)
qm terminal <vmid>
```

#### Step 2: Verify Minio Service

```bash
# SSH to Minio VM
ssh <minio-ip>

# Check Minio service
systemctl status minio

# If not running, start it
systemctl start minio

# Verify buckets exist
mc alias set myminio http://localhost:9000 admin <password>
mc ls myminio/

# Verify terraform-state bucket
mc ls myminio/terraform-state/

# Check encryption and versioning
mc encrypt info myminio/terraform-state
mc version info myminio/terraform-state
```

#### Step 3: Restore Terraform Environment

```bash
# On recovery laptop/workstation

# Clone repository from GitHub
git clone https://github.com/<your-username>/proxmox-terraform
cd proxmox-terraform

# Decrypt secrets with Yubikey
# Insert Yubikey, enter PIN when prompted
sops --decrypt terraform.tfvars.enc > terraform.tfvars

# Update Proxmox API URL if IP changed
vim terraform.tfvars
# Update: proxmox_api_url = "https://<new-proxmox-ip>:8006/api2/json"

# Configure Minio backend
export AWS_ACCESS_KEY_ID="<minio-access-key>"
export AWS_SECRET_ACCESS_KEY="<minio-secret-key>"

# Update backend.tf if Minio IP changed
vim backend.tf
# Update: endpoint = "http://<minio-ip>:9000"

# Initialize Terraform
terraform init

# Verify state accessible
terraform show

# Check infrastructure status
terraform plan
# Should show differences if new Proxmox host has different config
```

#### Step 4: Create New Proxmox API Token

```bash
# In Proxmox UI: Datacenter > Permissions > API Tokens
# Create new token: root@pam!terraform

# Or via CLI:
pvesh create /access/users/root@pam/token/terraform -privsep 0

# Copy token to terraform.tfvars
vim terraform.tfvars
# Update: proxmox_api_token_secret = "<new-token>"

# Re-encrypt secrets
sops --encrypt terraform.tfvars > terraform.tfvars.enc
rm terraform.tfvars

# Commit updated secrets
git add terraform.tfvars.enc
git commit -m "Update Proxmox API token after DR"
git push
```

### Phase 4: Restore Remaining Services (12-24 hours)

#### Restore VMs in Priority Order

```bash
# For each VM in priority order:

# 1. List backups for VM
pvesm list <pbs-storage> | grep vm-<vmid>

# 2. Restore VM
qmrestore <pbs-storage>:backup/<backup-path> <vmid>

# 3. Update network config if needed
qm set <vmid> -ipconfig0 ip=<vm-ip>/24,gw=<gateway>

# 4. Start VM
qm start <vmid>

# 5. Verify service functionality
# Check logs, test access, etc.

# 6. Update documentation
# Note any IP changes or configuration differences
```

#### Restore LXC Containers

```bash
# For each container:

# 1. Restore container
pct restore <ctid> <pbs-storage>:backup/<backup-path>

# 2. Update network if needed
pct set <ctid> -net0 name=eth0,bridge=vmbr0,ip=<ct-ip>/24,gw=<gateway>

# 3. Start container
pct start <ctid>

# 4. Verify functionality
pct enter <ctid>
```

### Phase 5: Validation & Documentation (24-48 hours)

#### Service Validation Checklist

- [ ] All Tier 1 services restored and functional
- [ ] All Tier 2 services restored and functional
- [ ] All Tier 3 services restored and functional
- [ ] Terraform can manage infrastructure
- [ ] Backups configured and running
- [ ] Monitoring restored (if applicable)
- [ ] DNS records updated
- [ ] Firewall rules configured
- [ ] All services accessible
- [ ] Test key workflows

#### Documentation Updates

1. Update [infrastructure.md](../infrastructure.md) with any changes
2. Update [network.md](../network.md) with new IPs
3. Update [services.md](../services.md) with configuration changes
4. Document lessons learned
5. Update this runbook with improvements

#### Post-Recovery Tasks

- [ ] Configure local PBS for future backups
- [ ] Set up remote replication again
- [ ] Review and improve DR procedures
- [ ] Update emergency contact information
- [ ] Test backups after restoration
- [ ] Schedule post-mortem review

## DR Scenario: Secrets Compromise

### Indicators of Compromise

- Yubikey lost or stolen
- Unauthorized Proxmox API access
- Unauthorized Minio access
- GitHub account compromised
- terraform.tfvars file exposed

### Immediate Actions (0-1 hour)

#### 1. Revoke Compromised Credentials

**Proxmox API Token:**
```bash
# Delete compromised token
pvesh delete /access/users/root@pam/token/terraform

# Create new token
pvesh create /access/users/root@pam/token/terraform-new -privsep 0
```

**Minio Access Keys:**
```bash
# Delete compromised service account
mc admin user remove myminio terraform-user

# Create new user and service account
mc admin user add myminio terraform-user-new $(openssl rand -base64 24)
mc admin user svcacct add myminio terraform-user-new
```

**GitHub:**
- Enable account recovery mode
- Change password immediately
- Review access logs
- Enable additional 2FA methods

#### 2. Rotate Yubikey Keys (if compromised)

```bash
# If Yubikey lost/stolen, use backup Yubikey

# Re-encrypt all secrets with new Yubikey
# Insert new/backup Yubikey
age-plugin-yubikey --generate --slot 82 --pin-policy once

# Update .sops.yaml with new public key
vim .sops.yaml

# Re-encrypt secrets
sops updatekeys terraform.tfvars.enc

# Commit changes
git add .sops.yaml terraform.tfvars.enc
git commit -m "Security: Rotate Yubikey keys after compromise"
git push
```

#### 3. Audit Access Logs

**Proxmox:**
```bash
# Check API access logs
journalctl -u pveproxy | grep -i terraform
```

**Minio:**
```bash
# Check Minio audit logs
mc admin logs myminio --type audit
```

### Recovery Actions (1-4 hours)

1. Update all documentation with new credentials
2. Test Terraform access with new credentials
3. Verify no unauthorized changes to infrastructure
4. Review and improve secrets management
5. Document incident and remediation
6. Update security procedures

### Prevention Measures

- Always use Yubikey for secrets encryption
- Never commit plaintext secrets
- Regular credential rotation schedule
- Enable audit logging on all services
- Use dedicated API tokens with minimal permissions
- Store backup Yubikey in secure off-site location

## DR Testing Schedule

### Monthly Tests
- Restore single VM from backup
- Test Terraform state recovery
- Verify remote PBS accessibility

### Quarterly Tests
- Full Proxmox host recovery simulation
- Secrets rotation drill
- Update DR documentation

### Annual Tests
- Complete site loss simulation
- Full DR procedure walkthrough
- Validate all emergency contacts
- Review and update RTO/RPO targets

## Recovery Time Objectives (RTO)

| Scenario | Target RTO | Actual RTO | Status |
|----------|-----------|------------|--------|
| Single VM | 15 min | TBD | Not tested |
| Minio VM | 30 min | TBD | Not tested |
| Proxmox Host | 4 hours | TBD | Not tested |
| Complete Site | 2 days | TBD | Not tested |

## Recovery Point Objectives (RPO)

| Data Type | Target RPO | Method |
|-----------|-----------|--------|
| VM data | 24 hours | PBS daily backup |
| Terraform state | Real-time | Minio versioning |
| Configuration | On commit | Git |
| Secrets | On commit | Git (encrypted) |

## Emergency Contacts

| Role | Name | Phone | Email | Availability |
|------|------|-------|-------|--------------|
| Primary Admin | TBD | TBD | TBD | 24/7 |
| Backup Admin | TBD | TBD | TBD | Business hours |
| Hardware Vendor | TBD | TBD | TBD | Support hours |
| ISP Support | TBD | TBD | TBD | 24/7 |

## External Dependencies

| Service | Contact | Criticality | Alternative |
|---------|---------|-------------|-------------|
| GitHub | - | High | Local git bundle |
| Remote PBS | TBD | Critical | None |
| ISP | TBD | Critical | Mobile hotspot |

## Lessons Learned

Document lessons learned after each DR test or real incident:

| Date | Incident/Test | Lessons Learned | Actions Taken |
|------|---------------|----------------|---------------|
| TBD | - | - | - |

## Appendix

### Required Tools for DR

**Software:**
- Proxmox VE ISO (latest)
- Terraform binary
- Git client
- SOPS + age + age-plugin-yubikey
- SSH client
- Text editor

**Hardware:**
- Bootable USB with Proxmox installer
- Primary Yubikey
- Backup Yubikey
- Laptop for Terraform operations
- Console access equipment

**Information:**
- This DR runbook (printed copy)
- Network diagram (printed copy)
- Password manager access
- Remote PBS credentials

### Pre-Made Recovery USB

Create a USB drive with:
- Proxmox VE installer
- This documentation (PDF)
- Network diagrams
- Emergency contact list
- Terraform binary
- Required tools

Store in safe, accessible location.

### Related Documentation

- [Backup & Restore Runbook](backup-restore.md)
- [Infrastructure Inventory](../infrastructure.md)
- [Network Architecture](../network.md)
- [Security Setup](../../proxmox-terraform/SECURITY_SETUP.md)
